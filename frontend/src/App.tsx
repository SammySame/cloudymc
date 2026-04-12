import { useEffect, useContext, useRef } from 'react';
import { PrimeReactContext } from 'primereact/api';
import RJSFForm from '@rjsf/core';
import { Form } from '@rjsf/primereact';
import validator from '@rjsf/validator-ajv8';
import 'primeicons/primeicons.css';

import useTheme from './hooks/useTheme';
import ThemeToggle from './components/ThemeToggle';
import {
	ArrayFieldTitleTemplate,
	FieldErrorTemplate,
} from './components/FormTemplates';
import FormControls from './components/FormControls';

import { error } from './api/formHandlers';
import { useSchemas } from './hooks/useSchemas';
import { useInstanceManager } from './hooks/useInstanceManager';
import { minecraftEulaValidator } from './utils/validators';

export default function App() {
	const { changeTheme } = useContext(PrimeReactContext);
	const { isDark, toggle } = useTheme();

	const formRef = useRef<RJSFForm>(null);
	const { schema, uiSchema } = useSchemas();
	const {
		formData,
		instanceAddress,
		isInstanceRunning,
		isLoading,
		handleSubmit,
		handleTest,
		handleDestroy,
	} = useInstanceManager(formRef);

	useEffect(() => {
		changeTheme?.(
			`lara-${isDark ? 'light' : 'dark'}-purple`,
			`lara-${isDark ? 'dark' : 'light'}-purple`,
			'primereact-theme-dynamic',
			() => {}
		);
	}, [changeTheme, isDark]);

	return (
		<div style={{ maxWidth: '1000px', margin: '0 auto', padding: '20px' }}>
			<ThemeToggle isDark={isDark} toggle={toggle} />
			<Form
				ref={formRef}
				schema={schema}
				uiSchema={uiSchema}
				validator={validator}
				templates={{ ArrayFieldTitleTemplate, FieldErrorTemplate }}
				onSubmit={handleSubmit}
				onError={error}
				formData={formData}
				showErrorList={false}
				customValidate={minecraftEulaValidator}
			>
				<FormControls
					isLoading={isLoading}
					isRunning={isInstanceRunning}
					instanceAddress={instanceAddress}
					onTest={handleTest}
					onDestroy={handleDestroy}
				/>
			</Form>
		</div>
	);
}
