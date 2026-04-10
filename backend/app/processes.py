import json
import subprocess

from app.utils.stream_event import stream_event


def run_terraform(cwd: str = '.', dry_run=True):
	process = subprocess.Popen(
		['terraform', 'plan', '-input=false', '-no-color']
		if dry_run
		else ['terraform', 'apply', '-auto-approve', '-input=false', '-no-color'],
		cwd=cwd,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.STDOUT,
		text=True,
		bufsize=1,
	)

	assert process.stdout is not None
	for line in process.stdout:
		yield stream_event(f'[Terraform] {line.rstrip()}')

	process.wait()
	yield stream_event(
		f'[Terraform] Process finished with code: {process.returncode}', not process.returncode
	)
	if process.returncode != 0:
		return


def run_terraform_destroy(cwd: str = '.'):
	process = subprocess.Popen(
		['terraform', 'destroy', '-auto-approve', '-input=false', '-no-color'],
		cwd=cwd,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.STDOUT,
		text=True,
		bufsize=1,
	)

	assert process.stdout is not None
	for line in process.stdout:
		yield stream_event(f'[Terraform] {line.rstrip()}')

	process.wait()
	yield stream_event(
		f'[Terraform] Process finished with code: {process.returncode}', not process.returncode
	)
	if process.returncode != 0:
		return


def get_terraform_output(name: str, cwd: str = '.'):
	process = subprocess.run(
		['terraform', 'output', '-raw', '-no-color', name],
		cwd=cwd,
		capture_output=True,
		text=True,
		check=True,
	)
	return '' if 'Warning' in process.stdout else process.stdout


def get_terraform_state(cwd: str = '.'):
	process = subprocess.run(
		['terraform', 'state', 'list', '-no-color'],
		cwd=cwd,
		capture_output=True,
		text=True,
		check=True,
	)
	return process.stdout


def run_ansible(variables: dict, inventory: str, cwd: str = '.', dry_run=True):
	args = ['ansible-playbook', '-i', '/dev/stdin', '-e', json.dumps(variables), 'site.yml']
	if dry_run:
		args.append('--check')

	process = subprocess.Popen(
		args=args,
		cwd=cwd,
		stdin=subprocess.PIPE,
		stdout=subprocess.PIPE,
		stderr=subprocess.STDOUT,
		text=True,
		bufsize=1,
	)

	assert process.stdout and process.stdin is not None
	process.stdin.write(inventory)
	process.stdin.close()

	for line in process.stdout:
		yield stream_event(f'[Ansible] {line.rstrip()}')

	process.wait()
	yield stream_event(
		f'[Ansible] Process finished with code: {process.returncode}', not process.returncode
	)
	if process.returncode != 0:
		return
