import { Dialog } from 'primereact/dialog';

type ErrorDialogProps = {
	text: string;
	visible: boolean;
	onClose: () => void;
};

export default function ErrorDialog({
	text,
	visible,
	onClose,
}: ErrorDialogProps) {
	return (
		<Dialog
			header="Error"
			visible={visible}
			onHide={onClose}
			resizable={false}
			draggable={false}
		>
			<p className="m-0">{text}</p>
		</Dialog>
	);
}
