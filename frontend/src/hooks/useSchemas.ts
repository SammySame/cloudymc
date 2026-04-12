import { useState } from 'react';
import { RJSFSchema, UiSchema } from '@rjsf/utils';
import schemaFile from '../assets/bundled.schema.json';
import uiSchemaFile from '../assets/schemas/main.uischema.json';

function useSchemas() {
	const [schema, setSchema] = useState<RJSFSchema>(schemaFile as RJSFSchema);
	const [uiSchema, setUiSchema] = useState<UiSchema>(uiSchemaFile as UiSchema);

	if (import.meta.hot) {
		import.meta.hot.accept(
			['../assets/bundled.schema.json', '../assets/schemas/main.uischema.json'],
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

	return { schema, uiSchema };
}

export { useSchemas };
