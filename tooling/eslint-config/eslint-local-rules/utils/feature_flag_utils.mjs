import { existsSync, globSync, readFileSync } from 'node:fs';
import path from 'node:path';
import yaml from 'yaml';

const FEATURE_FLAG_PATHS = [
  'config/feature_flags',
  'ee/config/feature_flags',
  'jh/config/feature_flags',
];

// Organization flags don't get their own YAML file -- they're registered in
// this single registry and share a stage flag instead. See
// Organizations::Release::Registry.
const ORGANIZATION_RELEASE_REGISTRY_PATH = 'config/organizations_release.yml';

function snakeToCamel(str) {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

let cachedOrganizationReleaseFlags;

function getOrganizationReleaseFlags() {
  if (cachedOrganizationReleaseFlags !== undefined) {
    return cachedOrganizationReleaseFlags;
  }

  if (!existsSync(ORGANIZATION_RELEASE_REGISTRY_PATH)) {
    cachedOrganizationReleaseFlags = [];
    return cachedOrganizationReleaseFlags;
  }

  try {
    const content = readFileSync(ORGANIZATION_RELEASE_REGISTRY_PATH, 'utf8');
    const { flags } = yaml.parse(content) ?? {};

    cachedOrganizationReleaseFlags = (flags ?? []).flatMap((flag) =>
      typeof flag.name === 'string' ? [flag.name] : [],
    );
  } catch (error) {
    console.warn(
      `Warning: Could not parse ${ORGANIZATION_RELEASE_REGISTRY_PATH}: ${error.message}`,
    );
    cachedOrganizationReleaseFlags = [];
  }

  return cachedOrganizationReleaseFlags;
}

export function getAllFeatureFlags() {
  const flags = new Set();

  FEATURE_FLAG_PATHS.forEach((basePath) => {
    if (!existsSync(basePath)) {
      return;
    }

    try {
      const yamlFiles = globSync(`${basePath}/**/*.yml`);
      yamlFiles.forEach((filePath) => {
        const flagName = path.basename(filePath, '.yml');
        flags.add(flagName);
      });
    } catch (error) {
      console.warn(`Warning: Could not scan feature flags in ${basePath}: ${error.message}`);
    }
  });

  getOrganizationReleaseFlags().forEach((flagName) => flags.add(flagName));

  return flags;
}

export function convertFeatureFlagToCamelCase(snakeCaseFlag) {
  return snakeToCamel(snakeCaseFlag);
}

export function isFeatureFlagDefined(flagName) {
  const allFlags = getAllFeatureFlags();
  return allFlags.has(flagName);
}
