from flask import Flask

from app.routes import api_bp, static_bp

app = Flask(__name__, static_url_path='')
app.register_blueprint(static_bp)
app.register_blueprint(api_bp)
