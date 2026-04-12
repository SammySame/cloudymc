import { useState, useCallback } from 'react';

export function useError() {
	const [errorText, setErrorText] = useState<string>('');
	const [visible, setVisible] = useState<boolean>(false);

	const showError = useCallback((text: string) => {
		setErrorText(text);
		setVisible(true);
	}, []);

	const hideError = useCallback(() => {
		setVisible(false);
	}, []);

	return {
		errorText,
		visible,
		showError,
		hideError,
	};
}
