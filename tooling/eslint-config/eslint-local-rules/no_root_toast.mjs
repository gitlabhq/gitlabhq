import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

export const ROOT_TOAST_MESSAGE =
  '$root.$toast reads the toast off the app root, which only works while some bundle installs GlToastPlugin globally. Use showToast from ~/vue_shared/plugins/global_toast. GlToastMixin is not a drop-in replacement here: it parents the toaster to this component, so a toast shown as this component goes away disappears with it.';

/**
 * `$root.$toast` breaks once the global `Vue.use(GlToastPlugin)` installs are
 * gone, because the app root no longer carries the mixin. No fix is offered:
 * `GlToastMixin` ties the toast's lifetime to the calling component, while a
 * `$root` read outlives it, so the replacement depends on whether the call
 * site survives its own unmount. `vue-mixin-pairing` guards the local
 * `$toast` / `GlToastMixin` pairing.
 */
export const noRootToast = {
  meta: {
    type: 'problem',
    docs: {
      description: 'disallow reading the toast off the app root with $root.$toast',
    },
    schema: [],
  },
  create(context) {
    const report = (node) => context.report({ node, message: ROOT_TOAST_MESSAGE });

    return defineTemplateBodyVisitor(
      context,
      {
        'MemberExpression[object.name="$root"][property.name="$toast"]': report,
      },
      {
        'MemberExpression[property.name="$toast"][computed=false] > MemberExpression.object[property.name="$root"]':
          (node) => report(node.parent),
      },
    );
  },
};
