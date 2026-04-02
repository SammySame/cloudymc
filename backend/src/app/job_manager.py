import queue
import threading


class JobManager:
	def __init__(self):
		self._lock = threading.Lock()
		self._jobs: dict[str, queue.Queue] = {}

	def acquire(self) -> bool:
		return self._lock.acquire(blocking=False)

	def release(self):
		self._lock.release()

	def create(self, job_id: str) -> queue.Queue:
		q: queue.Queue = queue.Queue()
		self._jobs[job_id] = q
		return q

	def get(self, job_id: str) -> queue.Queue | None:
		return self._jobs.get(job_id)

	def remove(self, job_id: str):
		self._jobs.pop(job_id, None)


job_manager = JobManager()
