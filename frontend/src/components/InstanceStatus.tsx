import { Tag } from 'primereact/tag';

type InstanceStatusProps = {
	address: string;
	isRunning: boolean;
};

export default function InstanceStatus({
	address,
	isRunning,
}: InstanceStatusProps) {
	return (
		<Tag
			severity={isRunning ? 'success' : 'danger'}
			icon={isRunning ? 'pi pi-check-circle' : 'pi pi-times-circle'}
			value={`(${isRunning ? 'Online' : 'Offline'}) ${address ? address : 'Unknown'}`}
		/>
	);
}
