/* global RequestInit */
/* global RequestInfo */

async function submitForm(
	formData: any,
	tfDryRun = true,
	ansibleDryRun = true
) {
	const response = await getResponse('/api/forms/submit', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify([formData, tfDryRun, ansibleDryRun]),
	});
	const { jobId } = await response!.json();
	sessionStorage.setItem('jobId', jobId);
	return jobId;
}

async function streamJob(
	jobId: string,
	onLine: (stage: string, line: string) => void,
	onDone: (stage: string, returnCode: number) => void,
	onError: (message: string) => void
) {
	const response = await getResponse(`/api/forms/stream/${jobId}`, {
		method: 'GET',
	});

	const reader = response!.body!.getReader();
	const decoder = new TextDecoder();
	let buffer = '';

	try {
		while (true) {
			const { done, value } = await reader.read();
			if (done) break;

			buffer += decoder.decode(value, { stream: true });
			const lines = buffer.split('\n');
			buffer = lines.pop() ?? '';

			for (const line of lines.filter((l) => l.startsWith('data: '))) {
				let data: any;
				try {
					data = JSON.parse(line.slice(6));
				} catch (_) {
					console.warn('Failed to parse SSE line:', line);
					continue;
				}

				if (data.error) onError(data.error);
				else if (data.debug) console.log(data.debug);
				else if (data.done) onDone(data.stage, data.returnCode);
				else onLine(data.stage, data.line);
			}
		}
	} finally {
		reader.releaseLock();
		sessionStorage.removeItem('jobId');
	}
}

async function saveForm(formData: any) {
	await getResponse('/api/forms/save', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(formData),
	});
	console.log('User configuration saved successfully');
}

async function loadForm(fileName: string) {
	const response = await getResponse(`/api/forms/load?file_name=${fileName}`, {
		method: 'GET',
		headers: { Accept: 'application/json' },
	});
	return await response!.json();
}

async function getResponse(
	input: RequestInfo,
	init: RequestInit,
	options?: { retries?: number; cooldown?: number }
) {
	const { retries = 3, cooldown = 1000 } = options ?? {};

	for (let i = 0; i < retries + 1; i++) {
		let response: Response;
		try {
			response = await fetch(input, init);
		} catch (error) {
			if (i < retries) {
				console.log(
					`Failed to send network request. Retrying... (${i + 1}/${retries})`
				);
				await new Promise((resolve) => setTimeout(resolve, cooldown));
				continue;
			}
			throw error;
		}

		if (response.ok) {
			return response;
		} else if (i < retries && response.status >= 500) {
			console.log(
				`HTTP error: ${response.status}. Retrying... (${i + 1}/${retries})`
			);
			await new Promise((resolve) => setTimeout(resolve, cooldown));
			continue;
		}

		const body = await response.json().catch(() => null);
		throw new Error(body.error ?? `HTTP error: ${response.status}`);
	}
}

export { submitForm, saveForm, loadForm, streamJob };
