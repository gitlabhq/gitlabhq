import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

export const MISSING_MIXIN_MESSAGE =
  'glListeners()/glListener() is used but glListenersMixin is not registered in this file. Import it from ~/lib/utils/vue3compat/gl_listeners_mixin and add it to the component `mixins`, or the call throws at runtime.';

export const UNUSED_MIXIN_MESSAGE =
  'glListenersMixin is registered but neither glListeners() nor glListener() is used in this file. Remove the mixin.';

const MIXIN_NAME = 'glListenersMixin';
const METHOD_NAMES = new Set(['glListeners', 'glListener']);

/**
 * Pairing guard for the dual-runtime glListeners()/glListener(name) methods
 * (see `local-rules/vue3-gl-listeners`, which rewrites `$listeners` reads
 * into them):
 *
 * - a file using `glListeners()` or `glListener()` (template) or reading
 *   `this.glListeners`/`this.glListener` (script) must register
 *   `glListenersMixin`, or every call throws at runtime — possibly only on
 *   a conditionally rendered branch that no spec exercises;
 * - a file registering `glListenersMixin` without any usage carries dead
 *   weight that would also survive the eventual Vue-2-retirement codemod.
 *
 * The rule only sees same-file evidence: a mixin arriving indirectly
 * (through another mixin or `extends`) needs an `eslint-disable` with a
 * comment. No such composition exists in the codebase today.
 */
export const vue3GlListenersMixinPairing = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'require glListeners()/glListener() usage and the glListenersMixin registration to appear together in a component file',
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
        'CallExpression[callee.type="Identifier"]': (node) => {
          if (METHOD_NAMES.has(node.callee.name)) {
            usages.push(node);
          }
        },
        "VElement[parent.type!='VElement']:exit": finalize,
      },
      {
        // Both export shapes register mixins the same way:
        //   export default { mixins: [glListenersMixin] }
        //   export default normalizeRender({ mixins: [glListenersMixin] })
        'ExportDefaultDeclaration Property[key.name="mixins"] > ArrayExpression > Identifier':
          captureMixinRegistration,
        'MemberExpression[object.type="ThisExpression"][computed=false]': (node) => {
          if (METHOD_NAMES.has(node.property.name)) {
            usages.push(node);
          }
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
