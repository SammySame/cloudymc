import os

from flask import Flask, send_from_directory

PROJECT_ROOT_PATH = os.path.abspath(os.path.join(__file__, '..', '..', '..', '..'))
MODULE_ROOT_PATH = os.path.abspath(os.path.join(__file__, '..'))

app = Flask(
	__name__, static_folder=os.path.join(PROJECT_ROOT_PATH, 'frontend', 'dist'), static_url_path=''
)


@app.route('/')
def index():
	assert app.static_folder is not None
	return send_from_directory(app.static_folder, 'index.html')
