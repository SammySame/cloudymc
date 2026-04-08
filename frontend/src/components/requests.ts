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
	const { message, data } = await response!.json();

	console.log(message);
	sessionStorage.setItem('jobId', data);
	return data;
}

async function streamJob(jobId: string) {
	const response = await getResponse(`/api/forms/stream/${jobId}`, {
		method: 'GET',
	});

	const reader = response!.body!.getReader();
	const decoder = new TextDecoder();
	let buffer = '';
	let success = true;

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
				if (!data.ok) success = false;
				console.log(data.message);
			}
		}
	} finally {
		reader.releaseLock();
		sessionStorage.removeItem('jobId');
	}
	return success;
}

async function saveForm(formData: any) {
	const response = await getResponse('/api/forms/save', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(formData),
	});
	const { message } = await response!.json();
	console.log(message);
}

async function loadForm() {
	const response = await getResponse(`/api/forms/load`, {
		method: 'GET',
		headers: { Accept: 'application/json' },
	});
	const { message, data } = await response!.json();

	console.log(message);
	return data;
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
		throw new Error(body?.message ?? `HTTP error: ${response.status}`);
	}
}

export { submitForm, saveForm, loadForm, streamJob };
