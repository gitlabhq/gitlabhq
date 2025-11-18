const stylelint = require('stylelint');

const ruleName = 'gitlab/no-sass-class-concat';

const messages = stylelint.utils.ruleMessages(ruleName, {
  rejected: () => 'Class concatenation is disallowed',
});

const meta = {
  url: 'https://docs.gitlab.com/ee/development/fe_guide/style/scss.html#concatenating-classes',
};

/** @type {import('stylelint').Rule} */
const ruleFunction = (primary) => {
  return (root, result) => {
    const validOptions = stylelint.utils.validateOptions(result, ruleName, {
      actual: primary,
      possible: [true],
    });
    if (!validOptions) return;

    root.walkRules((ruleNode) => {
      // ruleNode.raws.selector.raw provides the SCSS text before processing/unrolling.
      const rawSelector = ruleNode.raws.selector ? ruleNode.raws.selector.raw : ruleNode.selector;

      if (rawSelector && /&[_-]/.test(rawSelector)) {
        stylelint.utils.report({
          result,
          ruleName,
          message: messages.rejected(),
          node: ruleNode,
          word: rawSelector,
        });
      }
    });
  };
};

ruleFunction.ruleName = ruleName;
ruleFunction.messages = messages;
ruleFunction.meta = meta;

module.exports = stylelint.createPlugin(ruleName, ruleFunction);
