/* global RequestInit */
/* global RequestInfo */

/**
 * Submits form data into backend and listens to server-sent events (SSE)
 * @param formData form data formatted as a JSON string.
 * @param tfDryRun If true, Terraform will list changes being made without applying them.
 * @param ansibleDryRun If true, Ansible will run most of the tasks without applying them.
 */
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

			const dataLines = lines.filter((l) => l.startsWith('data: '));
			for (const line of dataLines) {
				let data: any;
				try {
					data = JSON.parse(line.slice(6));
				} catch (_) {
					console.warn('Failed to parse SSE line:', line);
					continue;
				}

				if (data.error) {
					throw new Error(data.error);
				} else if (data.debug) {
					console.log(data.debug);
				} else if (data.done) {
					console.log(`[${data.stage}] finished with code: ${data.returnCode}`);
				} else {
					console.log(`[${data.stage}] ${data.line}`);
				}
			}
			if (buffer.startsWith('data: ')) {
				try {
					const data = JSON.parse(buffer.slice(6));
					console.log('Final chunk:', data);
				} catch (_) {
					/* discard */
				}
			}
		}
	} finally {
		reader.releaseLock();
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

export { submitForm, saveForm, loadForm };
