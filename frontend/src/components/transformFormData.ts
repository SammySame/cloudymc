export default function transformFormData(formData: Record<string, any>) {
	let formDataCopy = structuredClone(formData);

	// Combine ports into singular array for Terraform
	formDataCopy.dynamic = {};
	formDataCopy.dynamic.combinedPorts = formDataCopy.minecraft.additionalPorts;
	formDataCopy.dynamic.combinedPorts.push({
		number: formDataCopy.minecraft.serverPort,
		protocol: 'TCP',
	});

	// Prefix all SSH keys with the path to directory containing them
	const SSH_KEYS_PATH = '/etc/cloudymc/data/ssh';
	formDataCopy = deepSearchModify(formDataCopy, 'sshkey', (value) => {
		return `${SSH_KEYS_PATH}/${value}`;
	});

	return formDataCopy;
}

/**
 * Recursively search for keys containing a specific keyword and modify their string values.
 * @param obj JSON object to search.
 * @param keyword Substring to look for in the object keys (case insensitive).
 * @param modifier Function to run against matched key value.
 * @returns Modified copy of the provided JSON object.
 */
function deepSearchModify(
	obj: any,
	keyword: string,
	modifier: (value: any) => any
) {
	if (typeof obj !== 'object' || obj === null) {
		return obj;
	}

	const modifiedObj: any = {};
	for (const key of Object.keys(obj)) {
		const value = obj[key];

		if (key.toLowerCase().includes(keyword.toLowerCase())) {
			modifiedObj[key] = Array.isArray(value)
				? value.map((item: any) => modifier(item))
				: modifier(value);
		} else {
			if (Array.isArray(value)) {
				modifiedObj[key] = value.map((item: any) =>
					deepSearchModify(item, keyword, modifier)
				);
			} else if (value && typeof value === 'object') {
				modifiedObj[key] = deepSearchModify(value, keyword, modifier);
			} else {
				modifiedObj[key] = value;
			}
		}
	}

	return modifiedObj;
}
