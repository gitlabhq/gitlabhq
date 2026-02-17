/**
 * Extracts the urgency value from a GraphQL comment
 * @param {string} commentText - The comment text (without the leading #)
 * @returns {object|null} Object with urgency value and whether format is valid, or null if not found
 */
function extractUrgency(commentText) {
  // In GraphQL comments, the # is already stripped by the parser
  // Match: @urgency: <value> or @urgency:<value> (with or without space)
  // Note: proper format should have a space after the colon
  const matchWithSpace = commentText.match(/^\s+@urgency:\s+(.+)$/);
  const matchWithoutSpace = commentText.match(/^\s+@urgency:(\S+)/);

  if (matchWithSpace) {
    return { urgency: matchWithSpace[1].trim(), validFormat: true };
  }
  if (matchWithoutSpace) {
    return { urgency: matchWithoutSpace[1].trim(), validFormat: false };
  }

  return null;
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
 * Finds the urgency comment in the source code
 * @param {object} context - ESLint context
 * @returns {object|null} Object with urgency, validFormat, and location, or null if not found
 */
function findUrgencyComment(context) {
  const sourceCode = context.getSourceCode();
  const comments = sourceCode.getAllComments();

  for (const comment of comments) {
    const result = extractUrgency(comment.value);
    if (result) {
      return { urgency: result.urgency, validFormat: result.validFormat, comment };
    }
  }

  return null;
}

const VALID_URGENCIES = ['high', 'medium', 'default', 'low'];

export const graphqlRequireValidUrgency = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Ensures that GraphQL query, mutation, and subscription files have a valid @urgency comment if present',
      category: 'Best Practices',
    },
    messages: {
      invalidUrgency: 'Invalid urgency "{{ urgency }}". Must be one of: high, medium, default, low',
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

        const result = findUrgencyComment(context);

        // If there's no urgency comment, that's fine - it's optional
        if (!result) {
          return;
        }

        const { urgency, validFormat } = result;

        // Report invalid format or invalid urgency value
        if (!validFormat || !VALID_URGENCIES.includes(urgency)) {
          context.report({
            node: result.comment,
            messageId: 'invalidUrgency',
            data: { urgency },
          });
        }
      },
    };
  },
};
