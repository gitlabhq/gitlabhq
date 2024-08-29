const stylelint = require('stylelint');

const {
  createPlugin,
  utils: { report, ruleMessages, validateOptions },
} = stylelint;

const ruleName = 'gitlab/no-gl-class';

const messages = ruleMessages(ruleName, {
  rejected: () => '"gl-" class selectors are disallowed',
});

const meta = {
  url: 'https://docs.gitlab.com/ee/development/fe_guide/style/scss.html#selectors-with-util-css-classes',
};

/** @type {import('stylelint').Rule} */
const ruleFunction = (primary) => {
  return (root, result) => {
    const validOptions = validateOptions(result, ruleName, {
      actual: primary,
      possible: [true],
    });

    if (!validOptions) return;

    root.walkRules(/\.gl-/, (ruleNode) => {
      report({
        result,
        ruleName,
        message: messages.rejected(),
        node: ruleNode,
        word: ruleNode.selector,
      });
    });
  };
};

ruleFunction.ruleName = ruleName;
ruleFunction.messages = messages;
ruleFunction.meta = meta;

module.exports = createPlugin(ruleName, ruleFunction);
