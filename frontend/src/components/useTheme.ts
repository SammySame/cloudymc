import { useState, useEffect } from 'react';

const STORAGE_KEY = 'preferred-theme';

function getInitialTheme(): boolean {
	const stored = localStorage.getItem(STORAGE_KEY);
	if (stored === 'light') return false;
	if (stored === 'dark') return true;
	return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

export default function useTheme() {
	const [isDark, setIsDark] = useState<boolean>(getInitialTheme);

	useEffect(() => {
		document.documentElement.setAttribute(
			'data-theme',
			isDark ? 'dark' : 'light'
		);
	}, [isDark]);

	useEffect(() => {
		const mq = window.matchMedia('(prefers-color-scheme: dark)');
		const handler = (e: MediaQueryListEvent) => {
			if (!localStorage.getItem(STORAGE_KEY)) {
				setIsDark(e.matches);
			}
		};

		mq.addEventListener('change', handler);
		return () => mq.removeEventListener('change', handler);
	}, []);

	const toggle = () => {
		setIsDark((prev) => {
			const next = !prev;
			localStorage.setItem(STORAGE_KEY, next ? 'dark' : 'light');
			return next;
		});
	};

	return { isDark, toggle };
}
