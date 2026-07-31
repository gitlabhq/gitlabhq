// Flags `$scopedSlots` usage in .vue files and (where mechanical) rewrites
// it to the dual-runtime `glSlots()` method from
// app/assets/javascripts/lib/utils/vue3compat/gl_slots_mixin.js:
//
//   v-if="$scopedSlots.foo"           -> v-if="glSlots().foo"
//   this.$scopedSlots['foo']?.()      -> this.glSlots()['foo']?.()
//   v-for="(_, name) in $scopedSlots" -> v-for="(_, name) in glSlots()"
//
// `glSlots()` returns `$scopedSlots` on Vue 2 and `$slots` on Vue 3, so the
// rewrite is value-preserving on both runtimes (Vue 3 removed $scopedSlots;
// @vue/compat flags every access via INSTANCE_SCOPED_SLOTS; the Vue 2
// `$slots` is not a substitute because it misses slots passed with slot
// props).
//
// The first fixed site in a file also injects the `glSlotsMixin` import and
// registers it in the default export's `mixins` array. A file is
// auto-fixable only when its default export is a plain object expression
// whose `mixins` option (if present) is an array literal; script usages
// must be plain `this.$scopedSlots` member reads lexically inside the
// default export. Everything else is reported without a fix.
// See scripts/frontend/codemods/vue3_gl_slots.mjs for the batch codemod
// built on top of this rule.

import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

const MIXIN_NAME = 'glSlotsMixin';
const MIXIN_SOURCE = '~/lib/utils/vue3compat/gl_slots_mixin';
const MESSAGE =
  'Use the dual-runtime glSlots() (lib/utils/vue3compat/gl_slots_mixin) instead of $scopedSlots.';

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

export const vue3GlSlots = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Rewrite $scopedSlots usage to the dual-runtime glSlots() mixin method',
    },
    fixable: 'code',
    schema: [],
  },
  create(context) {
    const { sourceCode } = context;

    let exportObject = null;
    let lastImport = null;
    let hasMixinImport = false;
    const scriptUsages = [];
    const unfixableScriptUsages = [];
    let injectionPending = false;

    function isInsideExportObject(node) {
      let current = node;
      while (current) {
        if (current === exportObject) {
          return true;
        }
        current = current.parent;
      }
      return false;
    }

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
          const fixes = [fixer.replaceTextRange(replacementRange, 'glSlots()')];
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

    function flushScriptReports() {
      const fixable = canFixFile();

      unfixableScriptUsages.forEach((node) => reportUnfixable(node));

      scriptUsages.forEach((memberExpression, index) => {
        if (!fixable) {
          reportUnfixable(memberExpression);
          return;
        }
        // Rewrite the property name span only: `this.$scopedSlots` ->
        // `this.glSlots()` (also correct under optional chaining).
        reportUsage(memberExpression.property.range, index === 0);
      });

      injectionPending = fixable && scriptUsages.length === 0;
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
      "MemberExpression[property.name='$scopedSlots']": function captureScriptUsage(node) {
        if (node.computed) {
          unfixableScriptUsages.push(node);
          return;
        }
        if (node.object.type !== 'ThisExpression') {
          unfixableScriptUsages.push(node);
          return;
        }
        scriptUsages.push(node);
      },
      'Program:exit': function reportScriptUsages() {
        // Script usages outside the default export cannot see the mixin
        // method; treat them as unfixable.
        const [inside, outside] = [
          scriptUsages.filter((node) => isInsideExportObject(node)),
          scriptUsages.filter((node) => !isInsideExportObject(node)),
        ];
        scriptUsages.length = 0;
        scriptUsages.push(...inside);
        unfixableScriptUsages.push(...outside);
        flushScriptReports();
      },
    };

    let firstTemplateUsageFixed = false;

    const templateVisitor = {
      "Identifier[name='$scopedSlots']": function reportTemplateUsage(node) {
        if (!canFixFile()) {
          reportUnfixable(node);
          return;
        }
        const isFirstFixed = injectionPending && !firstTemplateUsageFixed;
        firstTemplateUsageFixed = firstTemplateUsageFixed || isFirstFixed;
        reportUsage(node.range, isFirstFixed);
      },
    };

    return defineTemplateBodyVisitor(context, templateVisitor, scriptVisitor);
  },
};
