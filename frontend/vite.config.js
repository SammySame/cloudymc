import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import $RefParser from '@apidevtools/json-schema-ref-parser';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const SCHEMA_PATH = path.resolve(__dirname, 'src/assets/schemas/');
const MAIN_SCHEMA_PATH = path.resolve(SCHEMA_PATH, 'main.schema.json');
const UI_SCHEMA_PATH = path.resolve(SCHEMA_PATH, 'main.uischema.json');
const OUTPUT_PATH = path.resolve(__dirname, 'src/assets/bundled.schema.json');

async function bundleSchema() {
	const schema = await $RefParser.bundle(MAIN_SCHEMA_PATH);

	fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
	fs.writeFileSync(OUTPUT_PATH, JSON.stringify(schema, null, 2));
	console.log(`[Schema Bundler] Schema bundled successfully: ${OUTPUT_PATH}`);
}

export default defineConfig({
	server: {
		host: true,
		port: 5173,
		proxy: {
			'/api': 'http://localhost:5000',
		},
	},
	plugins: [
		react(),
		{
			name: 'bundle-json-schema',

			async buildStart() {
				await bundleSchema();
			},

			async handleHotUpdate({ file, server }) {
				if (file.includes(SCHEMA_PATH)) {
					if (file.endsWith('.schema.json')) {
						console.log(`[Schema Bundler] Schema file modified: ${file}`);
						await bundleSchema();

						const bundledModule = server.moduleGraph.getModuleById(OUTPUT_PATH);
						if (bundledModule) {
							server.moduleGraph.invalidateModule(bundledModule);
						}
						return [];
					} else if (file === UI_SCHEMA_PATH) {
						console.log(`[Schema Bundler] Schema file modified: ${file}`);
					}
				}
			},
		},
	],
});
