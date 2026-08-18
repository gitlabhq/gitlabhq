import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

export const MISSING_MIXIN_MESSAGE =
  'glSlots() is used but glSlotsMixin is not registered in this file. Import it from ~/lib/utils/vue3compat/gl_slots_mixin and add it to the component `mixins`, or the call throws at runtime.';

export const UNUSED_MIXIN_MESSAGE =
  'glSlotsMixin is registered but glSlots() is never used in this file. Remove the mixin.';

const MIXIN_NAME = 'glSlotsMixin';

/**
 * Pairing guard for the dual-runtime glSlots() method (see
 * `local-rules/vue3-gl-slots`, which rewrites `$scopedSlots` reads into it):
 *
 * - a file using `glSlots()` (template) or `this.glSlots` (script) must
 *   register `glSlotsMixin`, or every call throws at runtime — possibly only
 *   on a conditionally rendered branch that no spec exercises;
 * - a file registering `glSlotsMixin` without any `glSlots()` usage carries
 *   dead weight that would also survive the eventual Vue-2-retirement
 *   codemod (which rewrites `glSlots()` to `$slots` and strips the mixin).
 *
 * The rule only sees same-file evidence: a mixin arriving indirectly
 * (through another mixin or `extends`) needs an `eslint-disable` with a
 * comment. No such composition exists in the codebase today.
 */
export const vue3GlSlotsMixinPairing = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'require glSlots() usage and the glSlotsMixin registration to appear together in a component file',
    },
    schema: [],
  },
  create(context) {
    const usages = [];
    let mixinElement = null;
    let finalized = false;

    const finalize = () => {
      if (finalized) {
        return;
      }
      finalized = true;

      if (usages.length > 0 && !mixinElement) {
        usages.forEach((node) => {
          context.report({ node, message: MISSING_MIXIN_MESSAGE });
        });
      } else if (usages.length === 0 && mixinElement) {
        context.report({ node: mixinElement, message: UNUSED_MIXIN_MESSAGE });
      }
    };

    const captureMixinRegistration = (node) => {
      if (node.name === MIXIN_NAME && !mixinElement) {
        mixinElement = node;
      }
    };

    return defineTemplateBodyVisitor(
      context,
      // Template body traversal runs after the script's Program:exit, so the
      // root element's exit sees the usages collected from both passes.
      {
        'CallExpression[callee.type="Identifier"][callee.name="glSlots"]': (node) => {
          usages.push(node);
        },
        "VElement[parent.type!='VElement']:exit": finalize,
      },
      {
        // Both export shapes register mixins the same way:
        //   export default { mixins: [glSlotsMixin] }
        //   export default normalizeRender({ mixins: [glSlotsMixin] })
        'ExportDefaultDeclaration Property[key.name="mixins"] > ArrayExpression > Identifier':
          captureMixinRegistration,
        'MemberExpression[object.type="ThisExpression"][property.name="glSlots"][computed=false]': (
          node,
        ) => {
          usages.push(node);
        },
        'Program:exit': (node) => {
          if (!node.templateBody) {
            finalize();
          }
        },
      },
    );
  },
};
