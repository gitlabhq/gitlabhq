import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'yaml';

const dirname = path.dirname(fileURLToPath(import.meta.url));

// Load valid feature categories from the YAML file
let validCategories = [];
try {
  const categoriesPath = path.resolve(dirname, '../../../config/feature_categories.yml');
  const categoriesContent = readFileSync(categoriesPath, 'utf8');
  validCategories = yaml.parse(categoriesContent);
} catch (error) {
  // If we can't load the categories, the rule will still check for the comment presence
  console.warn('Warning: Could not load feature_categories.yml:', error.message);
}

/**
 * Extracts the feature category from a GraphQL comment
 * @param {string} commentText - The comment text (without the leading #)
 * @returns {string|null} The extracted category or null if not found
 */
function extractFeatureCategory(commentText) {
  // In GraphQL comments, the # is already stripped by the parser
  // Match: @feature_category: <value>
  // Note: whitespace matters - there should be a space after # (before @) and after :
  const match = commentText.match(/^\s+@feature_category:\s+(.+)$/);
  return match ? match[1].trim() : null;
}

/**
 * Checks if a GraphQL document contains mutation, query, or subscription operations (not just fragments)
 * @param {object} node - The GraphQL Document node
 * @returns {boolean} True if document contains mutation, query, or subscription operations
 */
function hasQueryMutationOrSubscription(node) {
  if (!node.definitions || !Array.isArray(node.definitions)) {
    return false;
  }

  return node.definitions.some((definition) => {
    return (
      definition.kind === 'OperationDefinition' &&
      (definition.operation === 'mutation' ||
        definition.operation === 'query' ||
        definition.operation === 'subscription')
    );
  });
}

/**
 * Finds the feature category comment in the source code
 * @param {object} context - ESLint context
 * @returns {object|null} Object with category and location, or null if not found
 */
function findFeatureCategoryComment(context) {
  const sourceCode = context.getSourceCode();
  const comments = sourceCode.getAllComments();

  for (const comment of comments) {
    const category = extractFeatureCategory(comment.value);
    if (category) {
      return { category, comment };
    }
  }

  return null;
}

export const graphqlRequireFeatureCategory = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Ensures that GraphQL query, mutation, and subscription files have a valid @feature_category comment',
      category: 'Best Practices',
    },
    messages: {
      missingCategory:
        'GraphQL query/mutation/subscription files must include a comment: # @feature_category: <category>',
      invalidFormat:
        'Feature category comment must follow the format: # @feature_category: <category> (note the spaces)',
      invalidCategory:
        'Invalid feature category "{{ category }}". Must be one of the categories defined in config/feature_categories.yml',
    },
    schema: [],
  },

  create(context) {
    return {
      Document(node) {
        // Only check files with query, mutation, or subscription operations (not fragments)
        if (!hasQueryMutationOrSubscription(node)) {
          return;
        }

        const result = findFeatureCategoryComment(context);

        if (!result) {
          context.report({
            node,
            loc: { line: 1, column: 0 },
            messageId: 'missingCategory',
          });
          return;
        }

        const { category } = result;

        // Validate the category against the list if we have it loaded
        if (validCategories.length > 0 && !validCategories.includes(category)) {
          context.report({
            node: result.comment,
            messageId: 'invalidCategory',
            data: { category },
          });
        }
      },
    };
  },
};
