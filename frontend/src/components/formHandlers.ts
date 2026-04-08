import { IChangeEvent } from '@rjsf/core';
import { RJSFValidationError } from '@rjsf/utils';
import { postBackend, submitForm, streamJob } from './requests';
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
		const jobId = await submitForm(transformFormData(formData), false, false);
		const success = await streamJob(jobId);
		if (!success) {
			console.error(
				'Process failed. Check the logs for the potential source of the issue'
			);
			return;
		}
		await postBackend(formData, '/api/forms/save');
	} catch (error) {
		console.error(`Failed to submit form data: ${error}`);
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

export { handleSubmit, handleError };
