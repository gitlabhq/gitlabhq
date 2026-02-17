import { existsSync, globSync } from 'node:fs';
import path from 'node:path';

const FEATURE_FLAG_PATHS = [
  'config/feature_flags',
  'ee/config/feature_flags',
  'jh/config/feature_flags',
];

function snakeToCamel(str) {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
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

  return flags;
}

export function convertFeatureFlagToCamelCase(snakeCaseFlag) {
  return snakeToCamel(snakeCaseFlag);
}

export function isFeatureFlagDefined(flagName) {
  const allFlags = getAllFeatureFlags();
  return allFlags.has(flagName);
}
