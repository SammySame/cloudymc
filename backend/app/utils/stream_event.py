import json


def stream_event(msg: str, ok=True):
	return f'data: {json.dumps({"message": msg, "ok": ok})}\n\n'
