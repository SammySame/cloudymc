import { CustomValidator } from '@rjsf/utils';

// Since defaulting boolean to false while requiring it to be true
// which would force the user to set it explicitly to true is impossible
// in RJSF, the value is checked here instead
const minecraftEulaValidator: CustomValidator<Record<string, any>> = function (
	formData,
	errors
) {
	if (formData?.minecraft?.eulaAccepted !== true) {
		errors?.minecraft?.eulaAccepted?.addError(
			'Minecraft EULA must be accepted'
		);
	}
	return errors;
};

export { minecraftEulaValidator };
