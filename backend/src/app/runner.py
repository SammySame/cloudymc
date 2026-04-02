import json
from collections.abc import Callable, Generator
from typing import Any

from .config import ANSIBLE_MAP_PATH, ANSIBLE_PATH, TF_PATH, TF_VARS_MAP_PATH, TF_VARS_PATH
from .processes import get_terraform_output, get_terraform_state, run_ansible, run_terraform
from .utils.json_helpers import flatten_json, load_json, map_json_keys, save_json
from .utils.ssh import add_known_hosts


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


def run_pipeline(data: tuple[dict, bool, bool]):
	try:
		tf_vars_map = load_json(TF_VARS_MAP_PATH)
	except Exception as e:
		yield _error_event(str(e))
		return

	config = data[0]
	flat_config = flatten_json(config)
	tf_vars = map_json_keys(flat_config, tf_vars_map)

	try:
		save_json(tf_vars, TF_VARS_PATH)
	except Exception as e:
		yield _error_event(str(e))
		return

	tf_dry_run = data[1]
	yield from _run_process(lambda: run_terraform(TF_PATH, tf_dry_run))

	tf_state = get_terraform_state(TF_PATH)
	if not tf_state or 'No state file was found!' in tf_state:
		yield f'data: {json.dumps({"stage": "terraform", "line": "Ansible won't be run due to missing/empty Terraform state file"})}\n\n'
		return

	public_ssh_key_contents: str = get_terraform_output('public_ssh_key_contents', TF_PATH)
	if not public_ssh_key_contents:
		yield _error_event('Empty Terraform output for: instance public SSH key contents')
		return

	ansible_inventory: str = get_terraform_output('ansible_inventory', TF_PATH)
	if not ansible_inventory:
		yield _error_event('Empty Terraform output for: Ansible inventory')
		return

	try:
		add_known_hosts(public_ssh_key_contents)
	except Exception as e:
		yield _error_event(str(e))
		return

	try:
		ansible_map = load_json(ANSIBLE_MAP_PATH)
	except Exception as e:
		yield _error_event(str(e))
		return

	ansible_dry_run = data[2]
	ansible_vars = map_json_keys(flat_config, ansible_map)
	yield from _run_process(
		lambda: run_ansible(ansible_vars, ansible_inventory, ANSIBLE_PATH, ansible_dry_run)
	)
