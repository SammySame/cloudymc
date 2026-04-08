import json
import os
import subprocess


def stream_event(msg: str):
	return f'data: {json.dumps(msg)}\n\n'


def load_environment_variable(name: str):
	env_var = os.getenv(name)
	if not env_var:
		raise RuntimeError(f'Environment variable {name} is missing or empty')
	return env_var


def add_known_hosts(host: str, path='~/.ssh/known_hosts'):
	try:
		result = subprocess.run(['ssh-keyscan', host], capture_output=True, text=True, check=True)
	except subprocess.CalledProcessError as e:
		raise RuntimeError(
			f'ssh-keyscan finished with return code: {e.returncode}\n{e.stderr}'
		) from None

	host_keys = result.stdout.split('\n')
	host_keys = filter(lambda key: not key.startswith('#'), host_keys)

	known_hosts_path = os.path.expanduser(path)
	try:
		with open(known_hosts_path, 'w') as file:
			file.write('\n'.join(host_keys).lstrip() + '\n')
	except PermissionError:
		raise PermissionError(
			f'Insufficient permissions to write into: {known_hosts_path}'
		) from None
	except Exception:
		raise Exception(f'Cloud not save known_hosts file at: {known_hosts_path}') from None
	os.chmod(known_hosts_path, 0o600)
