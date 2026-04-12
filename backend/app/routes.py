import os.path
import threading
import uuid
from collections.abc import Callable
from typing import Any

from flask import Blueprint, Response, jsonify, request, stream_with_context

from app.config import CONFIG_FILE_NAME, TF_PATH
from app.processes import get_terraform_output, run_terraform_destroy
from app.runner import run_pipeline
from app.utils.job_manager import job_manager
from app.utils.json_helpers import load_json, save_json
from app.utils.other import load_environment_variable

api_bp = Blueprint('api', __name__, url_prefix='/api')
static_bp = Blueprint('static', __name__, static_folder='static', static_url_path='/static')


@static_bp.route('/')
def index():
	assert static_bp.static_folder is not None
	return static_bp.send_static_file('index.html')


@api_bp.route('/terraform/output', methods=['GET'])
def get_output():
	name = request.args.get('name')
	if name is None:
		return jsonify(_format_response('Invalid or missing query string')), 400
	try:
		output = get_terraform_output(name, TF_PATH)
	except Exception as e:
		return jsonify(_format_response(str(e))), 500
	if not name:
		return jsonify(_format_response(f'Could not get Terraform output: {name}')), 204
	return jsonify(_format_response(f'Successfully retrieved: {name}', output)), 200


@api_bp.route('/terraform/destroy', methods=['POST'])
def destroy():
	if not job_manager.acquire():
		return jsonify(_format_response('Previous request is already being processed')), 409
	job_id = _run_thread(lambda: run_terraform_destroy(TF_PATH))
	return jsonify(_format_response('Deletion process started...', job_id)), 200


@api_bp.route('/forms/save', methods=['POST'])
def save_config():
	config = request.json
	try:
		user_data_path = load_environment_variable('USER_DATA_PATH')
		save_json(config, os.path.join(user_data_path, CONFIG_FILE_NAME))
		return jsonify(
			_format_response(f'File saved successfully: {user_data_path}/{CONFIG_FILE_NAME}')
		), 200
	except Exception as e:
		return jsonify(_format_response(str(e))), 500


@api_bp.route('/forms/load', methods=['GET'])
def load_config():
	try:
		user_data_path = load_environment_variable('USER_DATA_PATH')
		config = load_json(os.path.join(user_data_path, CONFIG_FILE_NAME))
		return jsonify(
			_format_response(
				f'File loaded successfully: {user_data_path}/{CONFIG_FILE_NAME}', config
			)
		)
	except FileNotFoundError as e:
		return jsonify(_format_response(str(e))), 404
	except Exception as e:
		return jsonify(_format_response(str(e))), 500


@api_bp.route('/forms/submit', methods=['POST'])
def apply_config():
	body: tuple[dict, bool, bool] = request.get_json(force=True)
	if body is None:
		return jsonify(_format_response('Invalid or missing JSON body')), 400
	if not job_manager.acquire():
		return jsonify(_format_response('Previous request is already being processed')), 409
	job_id = _run_thread(lambda: run_pipeline(body))
	return jsonify(_format_response('Initial process started...', job_id)), 200


@api_bp.route('/forms/stream/<job_id>', methods=['GET'])
def stream_job(job_id: str):
	q = job_manager.get(job_id)
	if q is None:
		return jsonify(_format_response('Unknown job ID')), 404

	def _generate():
		try:
			while True:
				event = q.get()
				if event is None:
					break
				yield event
		finally:
			job_manager.remove(job_id)

	return Response(stream_with_context(_generate()), mimetype='text/event-stream')


@api_bp.route('/compose-file-exists', methods=['GET'])
def compose_file_exists():
	user_data_path = load_environment_variable('USER_DATA_PATH')
	if os.path.exists(os.path.join(user_data_path, 'compose.yml')):
		return jsonify(_format_response('Custom compose file exists')), 200
	else:
		return jsonify(_format_response('Custom compose file does not exist')), 204


def _format_response(msg: str, data: Any | None = None):
	response = {'message': msg}
	if data:
		response['data'] = data
	return response


def _run_thread(func: Callable):
	job_id = str(uuid.uuid4())
	q = job_manager.create(job_id)

	def _run_thread():
		try:
			for event in func():
				q.put(event)
		finally:
			q.put(None)
			job_manager.release()

	threading.Thread(target=_run_thread, daemon=True).start()
	return job_id
