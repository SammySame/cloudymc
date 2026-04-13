import { useEffect, useContext, useRef, useCallback } from 'react';
import { PrimeReactContext } from 'primereact/api';
import { Dialog } from 'primereact/dialog';
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
import InfoDialog from './components/InfoDialog';

import { error } from './api/formHandlers';
import { useSchemas } from './hooks/useSchemas';
import { useInstanceManager } from './hooks/useInstanceManager';
import { useDialog } from './hooks/useDialog';
import { minecraftEulaValidator } from './utils/validators';

export default function App() {
	const { changeTheme } = useContext(PrimeReactContext);
	const { isDark, toggle } = useTheme();

	const formRef = useRef<RJSFForm>(null);
	const { schema, uiSchema } = useSchemas();
	const { header, body, visible, showDialog, hideDialog } = useDialog();

	const handleDialog = useCallback(
		(header: string, body: string) => {
			if (header.toLowerCase() === 'error') console.error(body);
			else console.info(body);
			showDialog(header, body);
		},
		[showDialog]
	);

	const {
		formData,
		instanceAddress,
		isInstanceRunning,
		isLoading,
		composeFileExists,
		setComposeFileExists,
		handleSubmit,
		handleTest,
		handleDestroy,
	} = useInstanceManager(formRef, handleDialog);

	useEffect(() => {
		changeTheme?.(
			`lara-${isDark ? 'light' : 'dark'}-purple`,
			`lara-${isDark ? 'dark' : 'light'}-purple`,
			'primereact-theme-dynamic',
			() => {}
		);
	}, [changeTheme, isDark]);

	return (
		<>
			<InfoDialog
				header={header}
				body={body}
				visible={visible}
				onClose={hideDialog}
			/>
			<Dialog
				header="Custom Compose file detected"
				position="bottom-right"
				draggable={false}
				resizable={false}
				modal={false}
				visible={composeFileExists}
				onHide={() => {
					if (!composeFileExists) return;
					setComposeFileExists(false);
				}}
				style={{ minWidth: '25em', maxWidth: '26vw' }}
			>
				<p className="m-0">
					Settings under the &quot;Minecraft&quot; category will be ignored in
					favor of the compose.yml, with the exception of the &quot;Server
					Port&quot; and &quot;Additional Ports&quot;, which need to match the
					compose.yml configuration.
				</p>
			</Dialog>
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
		</>
	);
}
