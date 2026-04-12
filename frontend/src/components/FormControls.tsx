import { Button } from 'primereact/button';
import InstanceStatus from './InstanceStatus';

type FormControlsProps = {
	isLoading: boolean;
	isRunning: boolean;
	instanceAddress: string;
	onTest: () => void;
	onDestroy: () => void;
};

export default function FormControls({
	isLoading,
	isRunning,
	instanceAddress,
	onTest,
	onDestroy,
}: FormControlsProps) {
	return (
		<>
			<div
				style={{
					padding: '2em',
					display: 'flex',
					justifyContent: 'space-around',
					alignItems: 'center',
				}}
			>
				<Button
					tooltip="Apply current configuration and save it on success"
					loading={isLoading}
					type="submit"
				>
					Submit
				</Button>
				<InstanceStatus
					id="instance-status"
					address={instanceAddress}
					isRunning={isRunning}
				/>
				<Button
					tooltip="Test the current configuration without saving and applying any changes"
					onClick={onTest}
					loading={isLoading}
					type="button"
				>
					Test
				</Button>
			</div>
			<div
				style={{
					paddingTop: '5em',
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'space-around',
				}}
			>
				<Button
					tooltip="Destroy instance and every resource associated with it in cloud"
					onClick={onDestroy}
					loading={isLoading}
					severity="danger"
					style={{ fontWeight: 'bold' }}
					type="button"
				>
					Destroy
				</Button>
			</div>
		</>
	);
}
