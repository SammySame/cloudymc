export default function transformFormData(formData: Record<string, any>) {
	let formDataCopy = structuredClone(formData);

	formDataCopy = combinePorts(formDataCopy);
	formDataCopy = prependPathToSshKeys(
		formDataCopy,
		'/etc/cloudymc/data/ssh_keys'
	);

	return formDataCopy;
}

function combinePorts(formData: Record<string, any>) {
	formData.dynamic = {};
	formData.dynamic.combinedPorts = structuredClone(
		formData.minecraft.additionalPorts || []
	);
	formData.dynamic.combinedPorts.push({
		number: formData.minecraft.serverPort,
		protocol: 'TCP',
	});
	return formData;
}

function prependPathToSshKeys(formData: Record<string, any>, path: string) {
	formData = deepSearchModify(formData, 'sshkey', (value) => {
		return `${path}/${value}`;
	});
	return formData;
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
