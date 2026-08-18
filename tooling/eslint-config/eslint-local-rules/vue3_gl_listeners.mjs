// Flags `$listeners` usage in .vue files and (where mechanical) rewrites
// template reads to the dual-runtime `glListeners()` method from
// app/assets/javascripts/lib/utils/vue3compat/gl_listeners_mixin.js:
//
//   v-on="$listeners"                   -> v-on="glListeners()"
//   v-on="{ ...$listeners, input: fn }" -> v-on="{ ...glListeners(), input: fn }"
//
// `glListeners()` returns `$listeners` on Vue 2 and under @vue/compat —
// production behavior is unchanged — and the map derived from the `$attrs`
// `onX` keys on plain Vue 3, where `$listeners` no longer exists. Handler
// references pass through untouched, so sites that also bind
// `v-bind="$attrs"` do not double-invoke (Vue's mergeProps skips the
// same-reference re-registration).
//
// The first fixed site in a file also injects the `glListenersMixin` import
// and registers it in the default export's `mixins` array. A file is
// auto-fixable only when its default export is a plain object expression
// whose `mixins` option (if present) is an array literal. Script reads of
// `this.$listeners` are always reported WITHOUT a fix: listener keys are
// spelled differently per runtime (Vue 2 keeps `step-click` as written,
// @vue/compat and plain Vue 3 camelize to `stepClick`), so named lookups
// must go through `glListener(name)` and iteration shapes need a per-site
// key-normalization decision.
// See scripts/frontend/codemods/vue3_gl_listeners.mjs for the batch codemod
// built on top of this rule.

import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

const MIXIN_NAME = 'glListenersMixin';
const MIXIN_SOURCE = '~/lib/utils/vue3compat/gl_listeners_mixin';
const MESSAGE =
  'Use the dual-runtime glListeners()/glListener() (lib/utils/vue3compat/gl_listeners_mixin) instead of $listeners.';

function getPropertyKeyName(property) {
  if (property.type !== 'Property' || property.computed) {
    return null;
  }
  if (property.key.type === 'Identifier') {
    return property.key.name;
  }
  if (property.key.type === 'Literal' && typeof property.key.value === 'string') {
    return property.key.value;
  }
  return null;
}

export const vue3GlListeners = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Rewrite $listeners usage to the dual-runtime glListeners() mixin method',
    },
    fixable: 'code',
    schema: [],
  },
  create(context) {
    const { sourceCode } = context;

    let exportObject = null;
    let lastImport = null;
    let hasMixinImport = false;

    function buildInjectionFixes(fixer) {
      const fixes = [];

      if (!hasMixinImport) {
        const importText = `import { ${MIXIN_NAME} } from '${MIXIN_SOURCE}';`;
        if (lastImport) {
          fixes.push(fixer.insertTextAfter(lastImport, `\n${importText}`));
        } else {
          // No imports yet: insert before the whole `export default` (the
          // object expression itself starts after the `export default`
          // keywords).
          fixes.push(fixer.insertTextBefore(exportObject.parent, `${importText}\n`));
        }
      }

      const mixinsProperty = exportObject.properties.find(
        (property) => getPropertyKeyName(property) === 'mixins',
      );

      if (mixinsProperty) {
        const { elements } = mixinsProperty.value;
        const alreadyRegistered = elements.some(
          (element) => element?.type === 'Identifier' && element.name === MIXIN_NAME,
        );
        if (!alreadyRegistered) {
          const lastElement = elements[elements.length - 1];
          if (lastElement) {
            fixes.push(fixer.insertTextAfter(lastElement, `, ${MIXIN_NAME}`));
          } else {
            fixes.push(fixer.replaceTextRange(mixinsProperty.value.range, `[${MIXIN_NAME}]`));
          }
        }
      } else {
        // `mixins` sits below name/components/directives in the
        // vue/order-in-components convention, so anchor on the last one.
        const anchor = exportObject.properties.findLast((property) =>
          ['components', 'directives', 'name'].includes(getPropertyKeyName(property)),
        );
        const insertion = `mixins: [${MIXIN_NAME}],`;
        if (anchor) {
          fixes.push(fixer.insertTextAfter(anchor, `,\n  ${insertion}`));

          // The anchor's trailing comma (if any) now duplicates the one we
          // added; prettier cannot fix `,,`, so consume it.
          const nextToken = sourceCode.getTokenAfter(anchor);
          if (nextToken && nextToken.value === ',') {
            fixes.push(fixer.remove(nextToken));
          }
        } else if (exportObject.properties.length > 0) {
          fixes.push(fixer.insertTextBefore(exportObject.properties[0], `${insertion}\n  `));
        } else {
          fixes.push(fixer.replaceTextRange(exportObject.range, `{ ${insertion} }`));
        }
      }

      return fixes;
    }

    function reportUsage(replacementRange, isFirstFixed) {
      context.report({
        loc: {
          start: sourceCode.getLocFromIndex(replacementRange[0]),
          end: sourceCode.getLocFromIndex(replacementRange[1]),
        },
        message: MESSAGE,
        fix(fixer) {
          const fixes = [fixer.replaceTextRange(replacementRange, 'glListeners()')];
          if (isFirstFixed) {
            fixes.push(...buildInjectionFixes(fixer));
          }
          return fixes;
        },
      });
    }

    function reportUnfixable(node) {
      context.report({ node, message: MESSAGE });
    }

    function canFixFile() {
      if (!exportObject) {
        return false;
      }
      const mixinsProperty = exportObject.properties.find(
        (property) => getPropertyKeyName(property) === 'mixins',
      );
      if (mixinsProperty && mixinsProperty.value.type !== 'ArrayExpression') {
        return false;
      }
      // A spread before the mixins insertion point could redefine options;
      // stay conservative when the object contains spreads and no mixins
      // array to extend.
      if (
        !mixinsProperty &&
        exportObject.properties.some((property) => property.type !== 'Property')
      ) {
        return false;
      }
      return true;
    }

    const scriptVisitor = {
      ImportDeclaration(node) {
        lastImport = node;
        if (
          node.source.value === MIXIN_SOURCE &&
          node.specifiers.some((specifier) => specifier.local.name === MIXIN_NAME)
        ) {
          hasMixinImport = true;
        }
      },
      'ExportDefaultDeclaration > ObjectExpression': function captureExportObject(node) {
        if (!exportObject) {
          exportObject = node;
        }
      },
      // Listener keys are runtime-dependent; script reads need a per-site
      // decision (glListener(name) for lookups), so never auto-fix them.
      "MemberExpression[property.name='$listeners']": function reportScriptUsage(node) {
        reportUnfixable(node);
      },
    };

    let firstTemplateUsageFixed = false;

    const templateVisitor = {
      "Identifier[name='$listeners']": function reportTemplateUsage(node) {
        if (!canFixFile()) {
          reportUnfixable(node);
          return;
        }
        const isFirstFixed = !firstTemplateUsageFixed;
        firstTemplateUsageFixed = true;
        reportUsage(node.range, isFirstFixed);
      },
    };

    return defineTemplateBodyVisitor(context, templateVisitor, scriptVisitor);
  },
};
