import { Attribute, ImageScanFinding } from "@aws-sdk/client-ecr";

// There are some vulnerabilities that, from the descriptions, clearly do not
// apply to us. If we don't do something about these, we would trigger alerts
// every day for every cluster we scan. In these cases, we can add the
// vulnerability info to this file so that it will be ignored by the scan.
type IgnoreSpec = {
  name: string;
  packageName: string;
  packageVersion?: Array<string>;
};

const ignoreSpecs = [
  {
    name: "CVE-2023-45853",
    packageName: "zlib",
    packageVersion: [
      "1:1.2.11.dfsg-2+deb11u2", // bullseye
      "1:1.2.13.dfsg-1", // bookworm
    ],
    // Note: The bug is in the minizip library, which the Debian documentation states is not
    // built as part of the packages.
  },
];

function attributeMatch(
  attrs: Array<Attribute>,
  key: string,
  value: Exclude<IgnoreSpec[keyof IgnoreSpec], undefined>,
): boolean {
  for (const attr of attrs) {
    if (attr.key === key) {
      return Array.isArray(value)
        ? value.some((v) => v === attr.value)
        : value === attr.value;
    }
  }

  return false;
}

function isFindingIgnoredBySpec(
  finding: ImageScanFinding,
  spec: IgnoreSpec,
): boolean {
  if (finding?.name !== spec.name) {
    return false;
  }

  if (!finding.attributes) {
    return false;
  }

  if (!attributeMatch(finding.attributes, "package_name", spec.packageName)) {
    return false;
  }

  if (
    spec.packageVersion &&
    !attributeMatch(finding.attributes, "package_version", spec.packageVersion)
  ) {
    return false;
  }

  return true;
}

function isFindingIgnoredBySpecs(
  finding: ImageScanFinding,
  specs: Array<IgnoreSpec>,
): boolean {
  for (const spec of specs) {
    if (isFindingIgnoredBySpec(finding, spec)) {
      return true;
    }
  }

  return false;
}

export function isFindingIgnored(finding: ImageScanFinding): boolean {
  return isFindingIgnoredBySpecs(finding, ignoreSpecs);
}
