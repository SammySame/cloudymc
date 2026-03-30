import json
import subprocess


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
		[
			'ansible-playbook',
			'-i',
			'/dev/stdin',
			'-e',
			json.dumps(variables),
			'site.yml',
			'--check' if not apply else '',
		],
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
		yield f'data: {json.dumps({"stage": "ansible", "line": line.rstrip()})}\n\n'

	process.wait()
	yield f'data: {json.dumps({"stage": "ansible", "done": True, "returnCode": process.returncode})}\n\n'
