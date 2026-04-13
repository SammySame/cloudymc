import { useState, useCallback } from 'react';

export function useDialog() {
	const [header, setHeader] = useState<string>('');
	const [body, setBody] = useState<string>('');
	const [visible, setVisible] = useState<boolean>(false);

	const showDialog = useCallback((header: string, body: string) => {
		setHeader(header);
		setBody(body);
		setVisible(true);
	}, []);

	const hideDialog = useCallback(() => {
		setVisible(false);
	}, []);

	return {
		header,
		body,
		visible,
		showDialog,
		hideDialog,
	};
}
