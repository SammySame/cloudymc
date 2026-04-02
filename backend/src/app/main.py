import json
import logging
import os.path
import queue
import threading
import uuid
from collections.abc import Callable, Generator
from typing import Any

from flask import Response, jsonify, request, stream_with_context

from app import MODULE_ROOT_PATH, PROJECT_ROOT_PATH, app

from .processes import get_terraform_output, get_terraform_state, run_ansible, run_terraform
from .utils.json_helpers import flatten_json, load_json, map_json_keys, save_json

logging.basicConfig(
	level=logging.INFO, format='%(asctime)s | %(levelname)s | %(message)s', datefmt='%H:%M:%S'
)

_pipeline_lock = threading.Lock()
_jobs: dict[str, queue.Queue] = {}

_CONFIG_PATH = os.path.join(PROJECT_ROOT_PATH, 'config', 'user')
_TF_PATH = os.path.join(PROJECT_ROOT_PATH, 'terraform')
_TF_VARS_PATH = os.path.join(PROJECT_ROOT_PATH, 'terraform', 'terraform.tfvars.json')
_TF_VARS_MAP_PATH = os.path.join(MODULE_ROOT_PATH, 'data', 'terraform_oci_map.json')
_ANSIBLE_PATH = os.path.join(PROJECT_ROOT_PATH, 'ansible')
_ANSIBLE_MAP_PATH = os.path.join(MODULE_ROOT_PATH, 'data', 'ansible_map.json')


@app.route('/api/forms/save', methods=['POST'])
def save_config():
	config = request.json
	try:
		save_json(config, os.path.join(_CONFIG_PATH, 'current_config.json'))
		return {}, 200
	except Exception as e:
		return jsonify({'error': str(e)}), 500


@app.route('/api/forms/load', methods=['GET'])
def load_config():
	file_name = request.args.get('file_name')
	try:
		return load_json(os.path.join(_CONFIG_PATH, f'{file_name}.json'))
	except FileNotFoundError as e:
		return jsonify({'error': str(e)}), 404
	except Exception as e:
		return jsonify({'error': str(e)}), 500


@app.route('/api/forms/submit', methods=['POST'])
def apply_config():
	body: tuple[dict, bool, bool] = request.get_json(force=True)
	if body is None:
		return jsonify({'error': 'Invalid or missing JSON body'}), 400

	if not _pipeline_lock.acquire(blocking=False):
		return jsonify({'error': 'Previous request is already being processed'}), 409

	job_id = str(uuid.uuid4())
	q: queue.Queue = queue.Queue()
	_jobs[job_id] = q

	def _run_thread():
		try:
			for event in run_pipeline(body):
				q.put(event)
		finally:
			q.put(None)
			_pipeline_lock.release()

	threading.Thread(target=_run_thread, daemon=True).start()
	return jsonify({'jobId': job_id}), 200


@app.route('/api/forms/stream/<job_id>', methods=['GET'])
def stream_job(job_id: str):
	q = _jobs.get(job_id)
	if q is None:
		return jsonify({'error': 'Unknown job ID'}), 404

	def _generate():
		try:
			while True:
				event = q.get()
				if event is None:
					break
				yield event
		finally:
			_jobs.pop(job_id, None)

	return Response(stream_with_context(_generate()), mimetype='text/event-stream')


def run_pipeline(data: tuple[dict, bool, bool]):
	def _error_event(message: str) -> str:
		return f'data: {json.dumps({"error": message})}\n\n'

	def _run_process(func: Callable[[], Generator[str, Any]]):
		for event in func():
			data = json.loads(event.replace('data: ', ''))
			if not data.get('done'):
				yield event
				continue
			if data.get('returnCode') == 0:
				yield event
				break
			else:
				yield _error_event(str(event))
				return

	try:
		tf_vars_map = load_json(_TF_VARS_MAP_PATH)
	except Exception as e:
		yield _error_event(str(e))
		return

	config = data[0]
	flat_config = flatten_json(config)
	tf_vars = map_json_keys(flat_config, tf_vars_map)

	try:
		save_json(tf_vars, _TF_VARS_PATH)
	except Exception as e:
		yield _error_event(str(e))
		return

	tf_dry_run = data[1]
	yield from _run_process(lambda: run_terraform(_TF_PATH, tf_dry_run))

	tf_state = get_terraform_state(_TF_PATH)
	if not tf_state or 'No state file was found!' in tf_state:
		yield f'data: {json.dumps({"stage": "terraform", "line": "Ansible won't be run due to missing/empty Terraform state file"})}\n\n'
		return

	public_ssh_key_contents: str = get_terraform_output('public_ssh_key_contents', _TF_PATH)
	if not public_ssh_key_contents:
		yield _error_event('Empty Terraform output for: instance public SSH key contents')
		return

	ansible_inventory: str = get_terraform_output('ansible_inventory', _TF_PATH)
	if not ansible_inventory:
		yield _error_event('Empty Terraform output for: Ansible inventory')
		return

	try:
		add_known_hosts(public_ssh_key_contents)
	except Exception as e:
		yield _error_event(str(e))
		return

	try:
		ansible_map = load_json(_ANSIBLE_MAP_PATH)
	except Exception as e:
		yield _error_event(str(e))
		return

	ansible_dry_run = data[2]
	ansible_vars = map_json_keys(flat_config, ansible_map)
	yield from _run_process(
		lambda: run_ansible(ansible_vars, ansible_inventory, _ANSIBLE_PATH, ansible_dry_run)
	)


def add_known_hosts(ssh_key: str, path='~/.ssh/known_hosts'):
	known_hosts_path = os.path.expanduser(path)
	try:
		with open(known_hosts_path, 'w') as file:
			file.write(ssh_key)
	except PermissionError:
		raise PermissionError(
			f'Insufficient permissions to write into: ${known_hosts_path}'
		) from None
	except Exception:
		raise Exception(f'Cloud not save known_hosts file at: ${known_hosts_path}') from None
	os.chmod(known_hosts_path, 0o600)


if __name__ == '__main__':
	app.run(debug=True)
