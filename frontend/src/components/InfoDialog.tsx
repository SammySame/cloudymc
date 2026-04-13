import { Dialog } from 'primereact/dialog';

type InfoDialogProps = {
	header: string;
	body: string;
	visible: boolean;
	onClose: () => void;
};

export default function InfoDialog({
	header,
	body,
	visible,
	onClose,
}: InfoDialogProps) {
	return (
		<Dialog
			header={header}
			visible={visible}
			onHide={onClose}
			resizable={false}
			draggable={false}
		>
			<p className="m-0">{body}</p>
		</Dialog>
	);
}
