import { titleId, FieldErrorProps, ArrayFieldTitleProps } from '@rjsf/utils';

// Don't show error info boxes since they bloat the form
function FieldErrorTemplate(_props: FieldErrorProps) {
	return null;
}

function ArrayFieldTitleTemplate(props: ArrayFieldTitleProps) {
	const { title, fieldPathId, required } = props;
	if (!title) return null;
	return (
		<h4 className="custom-array-title" id={titleId(fieldPathId)}>
			{title}
			{required && <span className="text-error ml-1"> *</span>}
		</h4>
	);
}

export { FieldErrorTemplate, ArrayFieldTitleTemplate };
