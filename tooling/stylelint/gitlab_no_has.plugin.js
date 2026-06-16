const stylelint = require('stylelint');

const {
  createPlugin,
  utils: { report, ruleMessages, validateOptions },
} = stylelint;

const ruleName = 'gitlab/no-has';

const PERFORMANCE_URL =
  'https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/:has#performance_considerations';

const messages = ruleMessages(ruleName, {
  rejected: () =>
    'The `:has()` pseudo-class is disallowed because it can severely degrade rendering performance, ' +
    'particularly through broad anchoring and unconstrained subtree traversal. ' +
    `See ${PERFORMANCE_URL}. ` +
    'If you must use it, scope it tightly and disable this rule with an explanation that covers ' +
    '(1) why the selector avoids broad anchoring and unconstrained subtree traversal, and ' +
    '(2) why `:has()` is the only viable solution. ' +
    'Example: `stylelint-disable-next-line gitlab/no-has -- anchored to a small, specific subtree; ' +
    'cannot toggle a class on the parent from JS because the child is rendered by code we do not control.`',
  missingDescription: () =>
    'A `stylelint-disable` comment for `gitlab/no-has` must include an explanation after `--`. ' +
    'The reason should cover (1) why the selector avoids broad anchoring and unconstrained subtree ' +
    `traversal (see ${PERFORMANCE_URL}), and (2) why \`:has()\` is the only viable solution. ` +
    'Example: `stylelint-disable-next-line gitlab/no-has -- anchored to a small, specific subtree; ' +
    'cannot toggle a class on the parent from JS because the child is rendered by code we do not control.`',
});

const meta = {
  url: PERFORMANCE_URL,
};

const HAS_PATTERN = /:has\(/;
const DISABLE_PREFIX = /^stylelint-disable(?:-next-line|-line)?\b/;

/** @type {import('stylelint').Rule} */
const ruleFunction = (primary) => {
  return (root, result) => {
    const validOptions = validateOptions(result, ruleName, {
      actual: primary,
      possible: [true],
    });

    if (!validOptions) return;

    root.walkRules((ruleNode) => {
      if (HAS_PATTERN.test(ruleNode.selector)) {
        report({
          result,
          ruleName,
          message: messages.rejected(),
          node: ruleNode,
          word: ':has',
        });
      }
    });

    root.walkComments((commentNode) => {
      const text = commentNode.text.trim();
      const prefixMatch = text.match(DISABLE_PREFIX);
      if (!prefixMatch) return;

      const rest = text.slice(prefixMatch[0].length).trim();
      const [rulesPart, ...descriptionParts] = rest.split(/\s+--\s+/);
      const description = descriptionParts.join(' -- ').trim();
      const rules = rulesPart.split(/[,\s]+/).filter(Boolean);
      if (!rules.includes(ruleName)) return;
      if (description) return;

      report({
        result,
        ruleName,
        message: messages.missingDescription(),
        node: commentNode,
      });
    });
  };
};

ruleFunction.ruleName = ruleName;
ruleFunction.messages = messages;
ruleFunction.meta = meta;

module.exports = createPlugin(ruleName, ruleFunction);
