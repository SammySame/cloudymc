import { useState, useEffect, useContext } from 'react';
import { IChangeEvent } from '@rjsf/core';
import { PrimeReactContext } from 'primereact/api';
import { Form } from '@rjsf/primereact';
import { Button } from 'primereact/button';
import validator from '@rjsf/validator-ajv8';
import { RJSFSchema, UiSchema, CustomValidator } from '@rjsf/utils';
import 'primeicons/primeicons.css';
import schemaFile from './assets/bundled.schema.json';
import uiSchemaFile from './assets/schemas/main.uischema.json';
import useTheme from './components/useTheme';
import ThemeToggle from './components/ThemeToggle';
import {
	ArrayFieldTitleTemplate,
	FieldErrorTemplate,
} from './components/FormTemplates';
import { getBackend } from './components/requests';
import InstanceStatus from './components/InstanceStatus';
import { submit, test, error, save } from './components/formHandlers';

export default function App() {
	const [schema, setSchema] = useState<RJSFSchema>(schemaFile as RJSFSchema);
	const [uiSchema, setUiSchema] = useState<UiSchema>(uiSchemaFile as UiSchema);
	const [formData, setFormData] = useState<any>(null);
	const { changeTheme } = useContext(PrimeReactContext);
	const { isDark, toggle } = useTheme();
	const [instanceAddress, setInstanceAddress] = useState<string>('');
	const [isRunning, setIsRunning] = useState(false);
	const [isLoading, setIsLoading] = useState(false);

	useEffect(() => {
		const fetchData = async () => {
			try {
				const data = await getBackend('/api/forms/load');
				if (data) setFormData(data);
			} catch (error) {
				console.error('Failed to load saved form data:', error);
			}
			try {
				const instance_ip = await getBackend('/api/instance/address');
				if (instance_ip) setInstanceAddress(instance_ip);
				const instance_status = await getBackend('/api/instance/running');
				if (instance_status !== null) setIsRunning(instance_status);
			} catch (error) {
				console.warn('Failed to retrieve cloud instance status:', error);
			}
		};
		fetchData();
	}, []);

	useEffect(() => {
		changeTheme?.(
			`lara-${isDark ? 'light' : 'dark'}-purple`,
			`lara-${isDark ? 'dark' : 'light'}-purple`,
			'primereact-theme-dynamic',
			() => {}
		);
	}, [changeTheme, isDark]);

	if (import.meta.hot) {
		import.meta.hot.accept(
			['./assets/bundled.schema.json', './assets/schemas/main.uischema.json'],
			([newSchemaModule, newUiSchemaModule]) => {
				if (newSchemaModule) {
					setSchema(newSchemaModule.default as RJSFSchema);
				}
				if (newUiSchemaModule) {
					setUiSchema(newUiSchemaModule.default);
				}
			}
		);
	}

	const handleSubmit = async (formData: IChangeEvent<any>) => {
		if (isRunning) {
			const input = prompt(
				'Any changes can result in cloud instance data loss.\n' +
					'Make sure to backup important data if neccessary.\n\n' +
					'Please type "yes" if you wish to continue'
			);
			if (input != 'yes') {
				console.log('Submit action cancelled');
				return;
			}
		}
		try {
			setIsLoading(true);
			await submit(formData);
		} catch (error) {
			console.error(`Failed submit action: ${error}`);
		} finally {
			setIsLoading(false);
		}
		try {
			setIsLoading(true);
			await save(formData);
		} catch (error) {
			console.error(`Failed to save form data: ${error}`);
		} finally {
			setIsRunning(false);
		}
	};

	const handleTest = async (data: IChangeEvent<any>) => {
		try {
			setIsLoading(true);
			await test(data);
		} catch (error) {
			console.error(`Failed test action: ${error}`);
		} finally {
			setIsLoading(false);
		}
	};

	// Since defaulting boolean to false while requiring it to be true
	// which would force the user to set it explicitly to true is impossible
	// in RJSF, the value is checked here instead
	const customValidate: CustomValidator<Record<string, any>> = function (
		formData,
		errors
	) {
		if (formData?.minecraft?.eulaAccepted !== true) {
			errors?.minecraft?.eulaAccepted?.addError(
				'Minecraft EULA must be accepted'
			);
		}
		return errors;
	};

	return (
		<div style={{ maxWidth: '1000px', margin: '0 auto', padding: '20px' }}>
			<ThemeToggle isDark={isDark} toggle={toggle} />
			<Form
				schema={schema}
				uiSchema={uiSchema}
				validator={validator}
				templates={{ ArrayFieldTitleTemplate, FieldErrorTemplate }}
				onSubmit={handleSubmit}
				onError={error}
				formData={formData}
				showErrorList={false}
				customValidate={customValidate}
			>
				<div
					style={{
						padding: '2em',
						display: 'flex',
						justifyContent: 'space-around',
						alignItems: 'center',
					}}
				>
					<Button
						tooltip="Apply current configuration and save it on success"
						loading={isLoading}
						type="submit"
					>
						Submit
					</Button>
					<InstanceStatus
						id="instance-status"
						address={instanceAddress}
						isRunning={isRunning}
					/>
					<Button
						tooltip="Test the current configuration without saving and applying any changes"
						onClick={(_) => handleTest(formData)}
						loading={isLoading}
						type="button"
					>
						Test
					</Button>
				</div>
			</Form>
		</div>
	);
}
