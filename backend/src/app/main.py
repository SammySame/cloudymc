import json
import logging
import os.path
import subprocess

from flask import Response, jsonify, request, stream_with_context

from app import MODULE_ROOT_DIR, PROJECT_ROOT_DIR, app

from .utils.json_helpers import flatten_json, load_json, map_json_keys, save_json

logging.basicConfig(
	level=logging.INFO, format='%(asctime)s | %(levelname)s | %(message)s', datefmt='%H:%M:%S'
)

CONFIG_PATH = os.path.join(PROJECT_ROOT_DIR, 'config', 'user')


@app.route('/api/forms/save', methods=['POST'])
def save_config():
	config = request.json
	try:
		save_json(config, os.path.join(CONFIG_PATH, 'current_config.json'))
		return {}, 200
	except Exception as e:
		return jsonify({'error': str(e)}), 500


@app.route('/api/forms/load', methods=['GET'])
def load_config():
	file_name = request.args.get('file_name')
	try:
		return load_json(os.path.join(CONFIG_PATH, f'{file_name}.json'))
	except FileNotFoundError as e:
		return jsonify({'error': str(e)}), 404
	except Exception as e:
		return jsonify({'error': str(e)}), 500


@app.route('/api/forms/submit', methods=['POST'])
def apply_config():
	body: tuple[dict, bool] = request.get_json(force=True)
	if body is None:
		return jsonify({'error': 'Invalid or missing JSON body'}), 400
	config = body[0]
	apply = body[1]
	return Response(stream_with_context(run_pipeline(config, apply)), mimetype='text/event-stream')


def run_pipeline(config: dict, apply=False):
	TERRAFORM_PATH = os.path.join(PROJECT_ROOT_DIR, 'terraform')
	ANSIBLE_PATH = os.path.join(PROJECT_ROOT_DIR, 'ansible')
	ANSIBLE_VARS_MAP_PATH = os.path.join(MODULE_ROOT_DIR, 'data', 'ansible_map.json')
	TF_VARS_PATH = os.path.join(PROJECT_ROOT_DIR, 'terraform', 'terraform.tfvars.json')
	TF_VARS_MAP_PATH = os.path.join(MODULE_ROOT_DIR, 'data', 'terraform_oci_map.json')

	try:
		tf_vars_map = load_json(TF_VARS_MAP_PATH)
	except Exception as e:
		yield f'data: {json.dumps({"error": str(e)})}\n\n'
		return

	flat_config = flatten_json(config)
	tf_vars = map_json_keys(flat_config, tf_vars_map)

	try:
		save_json(tf_vars, TF_VARS_PATH)
	except Exception as e:
		yield f'data: {json.dumps({"error": str(e)})}\n\n'
		return

	yield f'data: {json.dumps({"debug": tf_vars})}\n\n'

	for event in run_terraform(TERRAFORM_PATH, apply):
		yield event
		data = json.loads(event.replace('data: ', ''))
		if data.get('done') and data.get('returnCode') == 0:
			try:
				ansible_vars_map = load_json(ANSIBLE_VARS_MAP_PATH)
			except Exception as e:
				yield f'data: {json.dumps({"error": str(e)})}\n\n'
				return

			ansible_inventory: str = get_terraform_output('ansible_inventory', TERRAFORM_PATH)
			if not ansible_inventory:
				yield f'data: {json.dumps({"error": "The returned Ansible inventory is empty"})}\n\n'

			ansible_vars = map_json_keys(flat_config, ansible_vars_map)
			yield from run_ansible(ansible_vars, ansible_inventory, ANSIBLE_PATH)


def run_terraform(cwd: str = '.', apply=False):
	process = subprocess.Popen(
		['terraform', 'apply', '-auto-approve', '-input=false', '-no-color']
		if apply
		else ['terraform', 'plan', '-input=false', '-no-color'],
		cwd=cwd,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.STDOUT,
		text=True,
		bufsize=1,
	)

	assert process.stdout is not None
	for line in process.stdout:
		yield f'data: {json.dumps({"stage": "terraform", "line": line.rstrip()})}\n\n'

	process.wait()
	yield f'data: {json.dumps({"stage": "terraform", "done": True, "returnCode": process.returncode})}\n\n'


def get_terraform_output(name: str, cwd: str = '.'):
	process = subprocess.run(
		['terraform', 'output', '-raw', '-no-color', name], cwd=cwd, capture_output=True, text=True
	)
	return process.stdout


def run_ansible(variables: dict, inventory: str, cwd: str = '.', apply=False):
	process = subprocess.Popen(
		['ansible-playbook', '-i', inventory, '-e', json.dumps(variables)]
		if apply
		else ['ansible-playbook', '-i', inventory, '-e', json.dumps(variables), '--check'],
		cwd=cwd,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.STDOUT,
		text=True,
		bufsize=1,
	)

	assert process.stdout is not None
	for line in process.stdout:
		yield f'data: {json.dumps({"stage": "ansible", "line": line.rstrip()})}\n\n'

	process.wait()
	yield f'data: {json.dumps({"stage": "ansible", "done": True, "returnCode": process.returncode})}\n\n'


if __name__ == '__main__':
	app.run(debug=True)
