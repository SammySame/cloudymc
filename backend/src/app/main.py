import logging
import os.path
import threading
import uuid

from flask import Response, jsonify, request, stream_with_context

from app import app

from .config import USER_DATA_PATH
from .job_manager import job_manager
from .runner import run_pipeline
from .utils.json_helpers import load_json, save_json

logging.basicConfig(
	level=logging.INFO, format='%(asctime)s | %(levelname)s | %(message)s', datefmt='%H:%M:%S'
)


@app.route('/api/forms/save', methods=['POST'])
def save_config():
	config = request.json
	try:
		save_json(config, os.path.join(USER_DATA_PATH, 'current_config.json'))
		return {}, 200
	except Exception as e:
		return jsonify({'error': str(e)}), 500


@app.route('/api/forms/load', methods=['GET'])
def load_config():
	file_name = request.args.get('file_name')
	try:
		return load_json(os.path.join(USER_DATA_PATH, f'{file_name}.json'))
	except FileNotFoundError as e:
		return jsonify({'error': str(e)}), 404
	except Exception as e:
		return jsonify({'error': str(e)}), 500


@app.route('/api/forms/submit', methods=['POST'])
def apply_config():
	body: tuple[dict, bool, bool] = request.get_json(force=True)
	if body is None:
		return jsonify({'error': 'Invalid or missing JSON body'}), 400

	if not job_manager.acquire():
		return jsonify({'error': 'Previous request is already being processed'}), 409

	job_id = str(uuid.uuid4())
	q = job_manager.create(job_id)

	def _run_thread():
		try:
			for event in run_pipeline(body):
				q.put(event)
		finally:
			q.put(None)
			job_manager.release()

	threading.Thread(target=_run_thread, daemon=True).start()
	return jsonify({'jobId': job_id}), 200


@app.route('/api/forms/stream/<job_id>', methods=['GET'])
def stream_job(job_id: str):
	q = job_manager.get(job_id)
	if q is None:
		return jsonify({'error': 'Unknown job ID'}), 404

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


if __name__ == '__main__':
	app.run(debug=True)
