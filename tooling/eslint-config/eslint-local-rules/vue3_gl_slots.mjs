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
import {
  MIXIN_NAME,
  MIXIN_SOURCE,
  buildInjectionFixes,
  canInjectMixin,
} from './utils/gl_slots_mixin_injection.mjs';

const MESSAGE =
  'Use the dual-runtime glSlots() (lib/utils/vue3compat/gl_slots_mixin) instead of $scopedSlots.';

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
            fixes.push(
              ...buildInjectionFixes(fixer, { sourceCode, exportObject, lastImport, hasMixinImport }),
            );
          }
          return fixes;
        },
      });
    }

    function reportUnfixable(node) {
      context.report({ node, message: MESSAGE });
    }

    function canFixFile() {
      return canInjectMixin(exportObject);
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
