import { IChangeEvent } from '@rjsf/core';
import { RJSFValidationError } from '@rjsf/utils';
import { postBackend, streamJob } from './requests';
import transformFormData from './transformFormData';

async function handleSubmit(formData: IChangeEvent<any>, isRunning: boolean) {
	if (isRunning) {
		const input = prompt(
			'Any changes can result in cloud instance data loss.\n' +
				'Make sure to backup important data if neccessary.\n\n' +
				'Please type "yes" if you wish to continue'
		);
		if (input != 'yes') {
			console.log('Submit cancelled');
			return;
		}
	}
	try {
		const transFormData = transformFormData(formData);
		const jobId = await postBackend('/api/forms/submit', [
			transFormData,
			false,
			false,
		]);
		const success = await streamJob(jobId);
		if (!success) throw new Error('Process returned failure');
	} catch (error) {
		console.error(`Failed to submit: ${error}`);
	}
	try {
		await postBackend('/api/forms/save', formData);
	} catch (error) {
		console.error(`Failed to save form data: ${error}`);
	}
}

async function handleTest(formData: IChangeEvent<any>) {
	try {
		const transFormData = transformFormData(formData);
		const jobId = await postBackend('/api/forms/submit', [
			transFormData,
			true,
			true,
		]);
		const success = await streamJob(jobId);
		if (!success) throw new Error('Process returned failure');
	} catch (error) {
		console.error(`Failed to test submit: ${error}`);
	}
}

function handleError(errors: RJSFValidationError[]) {
	console.log('Validation error:', errors);
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

export { handleSubmit, handleTest, handleError };
