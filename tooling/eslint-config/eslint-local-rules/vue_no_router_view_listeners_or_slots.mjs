// Flags a bare <router-view> that binds a listener or receives slot content.
// Vue Router 4 (Vue 3) drops both silently; Vue Router 3 (Vue 2) forwards
// them. Use RouterViewWithSlot instead -- see MESSAGE below, and
// app/assets/javascripts/vue_shared/spa/components/router_view_with_slot.js
// for its retirement checklist, which also removes this rule.

import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';

export const MESSAGE =
  '<router-view> does not forward listeners or slot content to the routed component under Vue Router 4 (Vue 3), unlike Vue Router 3 (Vue 2). ' +
  'Use RouterViewWithSlot (~/vue_shared/spa/components/router_view_with_slot) instead, binding listeners and slots on the routed component itself: ' +
  '<router-view-with-slot #default="{ Component }"><component :is="Component" @your-event="handler">...</component></router-view-with-slot>.';

const hasListenerDirective = (el) =>
  (el.startTag?.attributes || []).some(
    (attribute) => attribute.directive && attribute.key.name.name === 'on',
  );

const hasSlotDirective = (el) =>
  (el.startTag?.attributes || []).some(
    (attribute) => attribute.directive && attribute.key.name.name === 'slot',
  );

const isMeaningfulChild = (node) => {
  if (node.type === 'VText') {
    return node.value.trim() !== '';
  }
  return true;
};

const hasMeaningfulChildren = (el) => (el.children || []).some((node) => isMeaningfulChild(node));

export const vueNoRouterViewListenersOrSlots = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Disallow listeners and slot content on a bare <router-view>, which Vue Router 4 silently drops',
    },
    schema: [],
  },
  create(context) {
    return defineTemplateBodyVisitor(context, {
      "VElement[name='router-view']": function checkRouterView(el) {
        if (hasListenerDirective(el) || hasSlotDirective(el) || hasMeaningfulChildren(el)) {
          context.report({ node: el.startTag, message: MESSAGE });
        }
      },
    });
  },
};
