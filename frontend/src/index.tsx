import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { PrimeReactProvider } from 'primereact/api';
import './index.css';

import App from './App';

const root = createRoot(document.getElementById('root')!);
root.render(
	<StrictMode>
		<PrimeReactProvider>
			<App />
		</PrimeReactProvider>
	</StrictMode>
);
