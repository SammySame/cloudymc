import { useState, useEffect, RefObject } from 'react';
import RJSFForm from '@rjsf/core';
import { getBackend } from '../api/requests';
import { submit, test, destroy, save } from '../api/formHandlers';

export function useInstanceManager(
	formRef: RefObject<RJSFForm | null>,
	onInfo: (header: string, body: string) => void
) {
	const [formData, setFormData] = useState<any>(null);
	const [instanceAddress, setInstanceAddress] = useState<string>('');
	const [isInstanceRunning, setIsInstanceRunning] = useState(false);
	const [isLoading, setIsLoading] = useState(false);
	const [composeFileExists, setComposeFileExists] = useState(false);

	useEffect(() => {
		const fetchData = async () => {
			try {
				const data = await getBackend('/api/forms/load');
				if (data) setFormData(data);
			} catch (error) {
				onInfo('Info', `Failed to load saved form data: ${error}`);
			}
			getInstanceStatus();
			checkComposeFileExists();
		};
		fetchData();
	}, [onInfo]);

	useEffect(() => {
		const interval = setInterval(getInstanceStatus, 30000);
		return () => clearInterval(interval);
	}, []);

	const getInstanceStatus = async () => {
		const [ip, status] = await Promise.all([
			getBackend('/api/terraform/output?name=instance_address'),
			getBackend('/api/terraform/output?name=is_instance_running'),
		]);
		if (ip) setInstanceAddress(ip);
		if (status !== null) setIsInstanceRunning(status);
	};

	const checkComposeFileExists = async () => {
		const exists = await getBackend('/api/compose-file-exists');
		if (exists !== null) setComposeFileExists(exists);
	};

	const performAction = async (action: () => Promise<void>) => {
		setIsLoading(true);
		let failed = false;
		try {
			await action();
		} catch (error) {
			onInfo('Error', `Action failed: ${error}`);
			failed = true;
		} finally {
			setIsLoading(false);
			if (!failed) onInfo('Info', 'Action finished successfully');
			await getInstanceStatus();
		}
	};

	const handleSubmit = async () => {
		if (isInstanceRunning) {
			const input = prompt(
				'Any changes can result in cloud instance data loss.\n' +
					'Make sure to backup important data if neccessary.\n\n' +
					'Please type "yes" if you wish to continue'
			);
			if (input !== 'yes') return;
		}

		performAction(async () => {
			await submit(formData);
			await save(formData);
			setIsInstanceRunning(false);
		});
	};

	const handleTest = () => {
		if (!formRef.current?.validateForm()) return;
		performAction(async () => {
			await test(formData);
		});
	};

	const handleDestroy = () => {
		const input = prompt(
			'All of the created cloud resources will be destroyed.\n' +
				'This action is irreversible.\n\n' +
				'Please type "yes" if you wish to continue'
		);
		if (input !== 'yes') return;

		performAction(async () => {
			await destroy();
			await save(formData);
		});
	};

	return {
		formData,
		setFormData,
		instanceAddress,
		isInstanceRunning,
		isLoading,
		composeFileExists,
		setComposeFileExists,
		handleSubmit,
		handleTest,
		handleDestroy,
	};
}
