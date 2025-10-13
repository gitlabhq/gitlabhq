const stylelint = require('stylelint');

const ruleName = 'gitlab/split-apply';
const messages = stylelint.utils.ruleMessages(ruleName, {
  expected: 'Expected @apply statements to have one class per line',
});

const ruleFunction = (primary, secondary, context) => {
  return (root, result) => {
    const validOptions = stylelint.utils.validateOptions(result, ruleName, {
      actual: primary,
    });

    if (!validOptions) {
      return;
    }

    root.walkAtRules('apply', (atRule) => {
      const params = atRule.params.trim();

      // Check if the @apply contains an !important flag (e.g., #{!important})
      const importantMatch = params.match(/\s+(#\{!important\}|!important)$/);
      const importantFlag = importantMatch ? importantMatch[1] : '';

      // Remove the !important flag from params before splitting
      const classesString = importantFlag ? params.slice(0, -importantFlag.length).trim() : params;

      const classes = classesString.split(/\s+/).filter(Boolean);

      // If there's more than one class, it needs to be split
      if (classes.length > 1) {
        if (context.fix) {
          // Get the indentation of the current @apply rule
          const indent = atRule.raws.before?.match(/[^\S\r\n]*$/)?.[0] || '';

          // Create new @apply rules for each class
          const newRules = classes.map((className, index) => {
            // Add the !important flag back to each class
            const newParams = importantFlag ? `${className} ${importantFlag}` : className;

            const newAtRule = atRule.clone({
              params: newParams,
            });

            // Preserve indentation for all but the first rule
            if (index > 0) {
              newAtRule.raws.before = `\n${indent}`;
            }

            return newAtRule;
          });

          // Replace the original rule with the split rules
          atRule.replaceWith(newRules);
        } else {
          // Just report the issue without fixing
          stylelint.utils.report({
            message: messages.expected,
            node: atRule,
            result,
            ruleName,
          });
        }
      }
    });
  };
};

ruleFunction.ruleName = ruleName;
ruleFunction.messages = messages;

module.exports = stylelint.createPlugin(ruleName, ruleFunction);
