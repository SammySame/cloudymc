import time

from app.config import ANSIBLE_MAP_PATH, ANSIBLE_PATH, TF_PATH, TF_VARS_MAP_PATH, TF_VARS_PATH
from app.processes import (
	get_terraform_output,
	get_terraform_state,
	run_ansible,
	run_terraform,
)
from app.utils.json_helpers import flatten_json, load_json, map_json_keys, save_json
from app.utils.other import add_known_hosts
from app.utils.stream_event import stream_event


def run_pipeline(data: tuple[dict, bool, bool]):
	try:
		tf_vars_map = load_json(TF_VARS_MAP_PATH)
	except Exception as e:
		yield stream_event(str(e), False)
		return

	config = data[0]
	flat_config = flatten_json(config)
	tf_vars = map_json_keys(flat_config, tf_vars_map)

	try:
		save_json(tf_vars, TF_VARS_PATH)
	except Exception as e:
		yield stream_event(str(e), False)
		return

	tf_dry_run = data[1]
	yield from run_terraform(TF_PATH, tf_dry_run)

	try:
		tf_state = get_terraform_state(TF_PATH)
	except Exception as e:
		yield stream_event(str(e), False)
		return
	if not tf_state or 'No state file was found!' in tf_state:
		yield stream_event(
			'Ansible cannot be run due to missing/empty Terraform state file', tf_dry_run
		)
		return

	try:
		ansible_inventory = get_terraform_output('ansible_inventory', TF_PATH)
	except Exception as e:
		yield stream_event(str(e), False)
		return
	if not ansible_inventory:
		yield stream_event('Empty Terraform output for: Ansible inventory', False)
		return

	try:
		instance_ip = get_terraform_output('instance_address', TF_PATH)
	except Exception as e:
		yield stream_event(str(e), False)
		return
	if not instance_ip:
		yield stream_event('Empty Terraform output for: Instance Address', False)
		return

	# If Instance is not yet online the ssh-keyscan will fail
	MAX_RETRIES = 3
	cooldown = 10
	success = False
	for i in range(MAX_RETRIES):
		try:
			add_known_hosts(instance_ip)
		except Exception as e:
			yield stream_event(
				f'{e!s}. Retrying after {cooldown} seconds... ({i + 1}/{MAX_RETRIES})'
			)
			time.sleep(cooldown)
			continue
		success = True
		break
	if not success:
		yield stream_event('Failed to retrieve instance SSH keys', False)

	try:
		ansible_map = load_json(ANSIBLE_MAP_PATH)
	except Exception as e:
		yield stream_event(str(e), False)
		return

	ansible_dry_run = data[2]
	ansible_vars = map_json_keys(flat_config, ansible_map)
	yield from run_ansible(ansible_vars, ansible_inventory, ANSIBLE_PATH, ansible_dry_run)
