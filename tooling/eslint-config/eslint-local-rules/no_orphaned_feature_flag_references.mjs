import { getAllFeatureFlags, convertFeatureFlagToCamelCase } from './utils/feature_flag_utils.mjs';

const FEATURE_FLAG_PATTERNS = ['glFeatures'];

let cachedCamelCaseFlags = null;

function getCamelCaseFlags() {
  if (cachedCamelCaseFlags !== null) {
    return cachedCamelCaseFlags;
  }

  const allFlags = getAllFeatureFlags();
  cachedCamelCaseFlags = new Set();

  allFlags.forEach((snakeCaseFlag) => {
    const camelCaseFlag = convertFeatureFlagToCamelCase(snakeCaseFlag);
    cachedCamelCaseFlags.add(camelCaseFlag);
  });

  return cachedCamelCaseFlags;
}

function extractPropertyName(node) {
  if (node.type === 'Identifier') {
    return node.name;
  }
  if (node.type === 'Literal') {
    return node.value;
  }
  return null;
}

export const noOrphanedFeatureFlagReferences = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Ensures that feature flag references in frontend code correspond to defined feature flags and are not orphaned after a feature flag is removed',
      recommended: true,
    },
    messages: {
      orphanedFlag:
        'Feature flag "{{ flagName }}" is not defined. It may have been removed from the backend.',
    },
    schema: [],
  },
  create(context) {
    const validFlags = getCamelCaseFlags();

    function checkFeatureFlagReference(node, featureFlagName) {
      if (!validFlags.has(featureFlagName)) {
        context.report({
          node,
          message:
            'Feature flag "{{ flagName }}" is not defined in any feature flag YAML files. This may be a reference to a removed feature flag.',
          data: {
            flagName: featureFlagName,
          },
        });
      }
    }

    return {
      MemberExpression(node) {
        if (
          node.object?.type === 'Identifier' &&
          FEATURE_FLAG_PATTERNS.includes(node.object.name)
        ) {
          const propertyName = extractPropertyName(node.property);
          if (propertyName) {
            checkFeatureFlagReference(node, propertyName);
          }
        }

        if (
          node.object?.type === 'MemberExpression' &&
          node.object.object?.type === 'ThisExpression' &&
          node.object.property?.type === 'Identifier' &&
          FEATURE_FLAG_PATTERNS.includes(node.object.property.name)
        ) {
          const propertyName = extractPropertyName(node.property);
          if (propertyName) {
            checkFeatureFlagReference(node, propertyName);
          }
        }
      },

      OptionalMemberExpression(node) {
        if (
          node.object?.type === 'Identifier' &&
          FEATURE_FLAG_PATTERNS.includes(node.object.name)
        ) {
          const propertyName = extractPropertyName(node.property);
          if (propertyName) {
            checkFeatureFlagReference(node, propertyName);
          }
        }

        if (
          node.object?.type === 'OptionalMemberExpression' &&
          node.object.object?.type === 'ThisExpression' &&
          node.object.property?.type === 'Identifier' &&
          FEATURE_FLAG_PATTERNS.includes(node.object.property.name)
        ) {
          const propertyName = extractPropertyName(node.property);
          if (propertyName) {
            checkFeatureFlagReference(node, propertyName);
          }
        }
      },
    };
  },
};
