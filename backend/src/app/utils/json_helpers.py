import json


def flatten_json(data: dict, parent_key: str = '', separator: str = '.') -> dict:
	items = {}
	for key, value in data.items():
		new_key = f'{parent_key}{separator}{key}' if parent_key else key
		if isinstance(value, dict):
			items.update(flatten_json(value, new_key, separator))
		else:
			items[new_key] = value
	return items


def map_json_keys(data: dict, mapping: dict) -> dict:
	return {mapping[key]: value for key, value in data.items() if key in mapping}


def load_json(file_path: str) -> dict:
	try:
		with open(file_path) as file:
			return json.load(file)
	except FileNotFoundError:
		raise FileNotFoundError(f'The following JSON file does not exist: {file_path}') from None
	except Exception as e:
		raise Exception('An error occurred while loading JSON file') from e


def save_json(data, output_path: str) -> None:
	try:
		with open(output_path, 'w') as file:
			json.dump(data, file, indent=2)
	except Exception:
		raise Exception('An error occurred while saving JSON file') from None
