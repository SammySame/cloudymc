import os


def load_environment_variable(name: str):
	env_var = os.getenv(name)
	if not env_var:
		raise RuntimeError(f'Environment variable {name} is missing or empty')
	return env_var


def add_known_hosts(ssh_key: str, path='~/.ssh/known_hosts'):
	known_hosts_path = os.path.expanduser(path)
	try:
		with open(known_hosts_path, 'w') as file:
			file.write(ssh_key)
	except PermissionError:
		raise PermissionError(
			f'Insufficient permissions to write into: {known_hosts_path}'
		) from None
	except Exception:
		raise Exception(f'Cloud not save known_hosts file at: {known_hosts_path}') from None
	os.chmod(known_hosts_path, 0o600)
