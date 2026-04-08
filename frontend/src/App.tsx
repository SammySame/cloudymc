import { useState, useEffect, useContext } from 'react';
import { PrimeReactContext } from 'primereact/api';
import { IChangeEvent } from '@rjsf/core';
import { Form } from '@rjsf/primereact';
import validator from '@rjsf/validator-ajv8';
import {
	RJSFSchema,
	UiSchema,
	CustomValidator,
	RJSFValidationError,
} from '@rjsf/utils';
import 'primeicons/primeicons.css';
import schemaFile from './assets/bundled.schema.json';
import uiSchemaFile from './assets/schemas/main.uischema.json';
import useTheme from './components/useTheme';
import ThemeToggle from './components/ThemeToggle';
import {
	ArrayFieldTitleTemplate,
	FieldErrorTemplate,
} from './components/FormTemplates';
import {
	getBackend,
	postBackend,
	submitForm,
	streamJob,
} from './components/requests';
import transformFormData from './components/transformFormData';

export default function App() {
	const [schema, setSchema] = useState<RJSFSchema>(schemaFile as RJSFSchema);
	const [uiSchema, setUiSchema] = useState<UiSchema>(uiSchemaFile as UiSchema);
	const [formData, setFormData] = useState<any>(null);
	const { changeTheme } = useContext(PrimeReactContext);
	const { isDark, toggle } = useTheme();

	useEffect(() => {
		const fetchData = async () => {
			try {
				const data = await getBackend('/api/forms/load');
				if (data) setFormData(data);
			} catch (error) {
				console.error('Failed to load saved form data:', error);
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

	const handleSubmit = async ({ formData }: IChangeEvent<any>) => {
		if (confirm())
			try {
				const jobId = await submitForm(
					transformFormData(formData),
					false,
					false
				);
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
	};

	const handleError = (errors: RJSFValidationError[]) => {
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
				onError={handleError}
				formData={formData}
				showErrorList={false}
				customValidate={customValidate}
			/>
		</div>
	);
}
