import { Button } from 'primereact/button';

interface ThemeToggleProps {
	isDark: boolean;
	toggle: () => void;
}

export default function ThemeToggle({ isDark, toggle }: ThemeToggleProps) {
	return (
		<Button
			onClick={toggle}
			aria-label={`Switch to ${isDark ? 'light' : 'dark'} mode`}
			label={isDark ? 'Light' : 'Dark'}
			icon={isDark ? 'pi pi-sun' : 'pi pi-moon'}
			severity="secondary"
			rounded
			style={{
				position: 'fixed',
				top: '1rem',
				right: '1rem',
				zIndex: 9999,
			}}
		/>
	);
}
