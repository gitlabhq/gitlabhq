const stylelint = require('stylelint');

const {
  createPlugin,
  utils: { report, ruleMessages, validateOptions },
} = stylelint;

const ruleName = 'gitlab/no-js-class';

const messages = ruleMessages(ruleName, {
  rejected: () => '"js-" prefixed selectors should not be used for styling',
});

const meta = {
  url: 'https://docs.gitlab.com/ee/development/fe_guide/style/scss.html#selectors-with-a-js-prefix',
};

const JS_PREFIX_PATTERN = /(\.js-|#js-)/;

/** @type {import('stylelint').Rule} */
const ruleFunction = (primary) => {
  return (root, result) => {
    const validOptions = validateOptions(result, ruleName, {
      actual: primary,
      possible: [true],
    });

    if (!validOptions) return;

    root.walkRules(JS_PREFIX_PATTERN, (ruleNode) => {
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
