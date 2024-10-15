const { existsSync, readFileSync } = require('fs');
const { getDocsFilePath, getAnchorsInMarkdown } = require('./utils/help_page_path_utils');

const TYPE_LITERAL = 'Literal';

/**
 * Extracts the anchor from a given `helpPagePath` call. The anchor can either be passed in the
 * first argument (eg '/path/to#anchor'). Or as the `anchor` property in the second argument.
 *
 * @param {object} node The node from which we are extracting the anchor
 * @returns {string?} The extracted anchor
 */
function getAnchor(node) {
  if (node.arguments.length === 1) {
    return node.arguments[0].value.match(/#(.+)$/)?.[1] ?? null;
  }
  return (
    node.arguments[1].properties
      .find((property) => {
        return property.key.name === 'anchor';
      })
      ?.value?.value.replace(/^#/, '') ?? null
  );
}

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Ensures that `helpPagePath` usages do not break when docs pages get moved around',
    },
  },
  create(context) {
    return {
      'CallExpression[callee.name="helpPagePath"]': (node) => {
        if (node.arguments.length === 0) {
          return;
        }

        if (node.arguments[0].type !== TYPE_LITERAL) {
          context.report({
            node,
            message: "`helpPagePath`'s first argument must be a string literal",
          });
          return;
        }

        const docsFilePath = getDocsFilePath(node.arguments[0].value);

        if (!existsSync(docsFilePath)) {
          context.report({
            node,
            message: '`{{ filePath }}` does not exist.',
            data: {
              filePath: docsFilePath,
            },
          });
          return;
        }

        const anchor = getAnchor(node);

        if (!anchor) {
          return;
        }

        const docsContent = readFileSync(docsFilePath);
        const anchors = getAnchorsInMarkdown(docsContent);

        if (!anchors.includes(anchor)) {
          context.report({
            node,
            message: '`#{{ anchor }}` not found in `{{ filePath }}`',
            data: {
              anchor,
              filePath: docsFilePath,
            },
          });
        }
      },
    };
  },
};
