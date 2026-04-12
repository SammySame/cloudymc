import { IChangeEvent } from '@rjsf/core';
import { RJSFValidationError } from '@rjsf/utils';
import { postBackend, streamJob } from '../api/requests';
import transformFormData from '../utils/transformFormData';

async function submit(formData: IChangeEvent<any>) {
	const transFormData = transformFormData(formData);
	const jobId = await postBackend('/api/forms/submit', [
		transFormData,
		false,
		false,
	]);
	const success = await streamJob(jobId);
	if (!success) throw new Error('Process returned failure');
}

async function test(formData: IChangeEvent<any>) {
	const transFormData = transformFormData(formData);
	const jobId = await postBackend('/api/forms/submit', [
		transFormData,
		true,
		true,
	]);
	const success = await streamJob(jobId);
	if (!success) throw new Error('Process returned failure');
}

async function destroy() {
	const jobId = await postBackend('/api/terraform/destroy');
	const success = await streamJob(jobId);
	if (!success) throw new Error('Process returned failure');
}

async function save(formData: IChangeEvent<any>) {
	await postBackend('/api/forms/save', formData);
}

function error(errors: RJSFValidationError[]) {
	if (!errors?.length) return;

	const prop = errors[0].property;
	if (!prop) return;

	const mod = prop.replace(/^\./, '').replace(/[.]/g, '_');
	const id = `root_${mod}`;
	const el = document.getElementById(id);
	if (!el) return;

	el.scrollIntoView({ behavior: 'smooth', block: 'center' });
	setTimeout(() => {
		const input = el.querySelector<HTMLElement>('input, select, textarea');
		input?.focus({ preventScroll: true });
	}, 300);
}

export { submit, test, destroy, save, error };
