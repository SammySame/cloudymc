import json
import logging
import os.path

from flask import Response, jsonify, request, stream_with_context

from app import MODULE_ROOT_PATH, PROJECT_ROOT_PATH, app

from .utils.json_helpers import flatten_json, load_json, map_json_keys, save_json
from .utils.processes import get_terraform_output, run_ansible, run_terraform

logging.basicConfig(
	level=logging.INFO, format='%(asctime)s | %(levelname)s | %(message)s', datefmt='%H:%M:%S'
)

CONFIG_PATH = os.path.join(PROJECT_ROOT_PATH, 'config', 'user')


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
	TERRAFORM_PATH = os.path.join(PROJECT_ROOT_PATH, 'terraform')
	ANSIBLE_PATH = os.path.join(PROJECT_ROOT_PATH, 'ansible')
	ANSIBLE_VARS_MAP_PATH = os.path.join(MODULE_ROOT_PATH, 'data', 'ansible_map.json')
	TF_VARS_PATH = os.path.join(PROJECT_ROOT_PATH, 'terraform', 'terraform.tfvars.json')
	TF_VARS_MAP_PATH = os.path.join(MODULE_ROOT_PATH, 'data', 'terraform_oci_map.json')

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

	for event in run_terraform(TERRAFORM_PATH, apply):
		yield event
		data = json.loads(event.replace('data: ', ''))

		if data.get('done') and data.get('returnCode') == 0:
			public_ssh_key_contents: str = get_terraform_output(
				'instance_public_ssh_key_contents', TERRAFORM_PATH
			)
			if not public_ssh_key_contents:
				yield f'data: {json.dumps({"error": "Empty Terraform output for: instance public SSH key contents"})}\n\n'
				return

			ansible_inventory: str = get_terraform_output('ansible_inventory', TERRAFORM_PATH)
			if not ansible_inventory:
				yield f'data: {json.dumps({"error": "Empty Terraform output for: Ansible inventory"})}\n\n'
				return

			try:
				add_known_hosts(public_ssh_key_contents)
			except Exception as e:
				yield f'data: {json.dumps({"error": str(e)})}\n\n'

			try:
				ansible_vars_map = load_json(ANSIBLE_VARS_MAP_PATH)
			except Exception as e:
				yield f'data: {json.dumps({"error": str(e)})}\n\n'
				return

			ansible_vars = map_json_keys(flat_config, ansible_vars_map)
			yield from run_ansible(ansible_vars, ansible_inventory, ANSIBLE_PATH)


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
