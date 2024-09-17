const { existsSync, readFileSync } = require('fs');
const { defineTemplateBodyVisitor } = require('./utils/eslint_parsing_utils');
const { getDocsFilePath, getAnchorsInMarkdown } = require('./utils/help_page_path_utils');

/**
 * Extracts the anchor from a given `HelpPageLink` component. The anchor can either be passed in the
 * `href` prop (eg '/path/to#anchor'), or as the `anchor` prop.
 *
 * @param {VStartTag} node The node from which we are extracting the anchor
 * @returns {string?} The extracted anchor
 */
function getAnchor(node) {
  if (node.attributes.length === 1) {
    return node.attributes[0].value.value.match(/#(.+)$/)?.[1] ?? null;
  }
  return node.attributes.find((attr) => attr.key.name === 'anchor')?.value?.value ?? null;
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
    return defineTemplateBodyVisitor(context, {
      'VElement[name="help-page-link"] > VStartTag': (node) => {
        const hrefAttribute = node.attributes.find((attr) => attr.key.name === 'href');

        if (!hrefAttribute) {
          context.report({
            node,
            message: 'The `href` prop must be passed as a string literal.',
          });
          return;
        }

        const docsFilePath = getDocsFilePath(hrefAttribute.value.value);

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
    });
  },
};
