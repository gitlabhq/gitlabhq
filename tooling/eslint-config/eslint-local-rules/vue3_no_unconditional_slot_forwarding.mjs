// Flags bare `<slot>` outlets forwarded unconditionally into a child
// component, and (where mechanical) guards them with the dual-runtime
// `glSlots()` presence check:
//
//   <child><slot></slot></child>
//     -> <child><template v-if="glSlots().default" #default><slot></slot></template></child>
//
//   <child><template #x><slot name="y"></slot></template></child>
//     -> <child><template v-if="glSlots().y" #x><slot name="y"></slot></template></child>
//
// Why: on Vue 2 a forwarded slot that receives nothing normalizes away — the
// child's `$scopedSlots.x` stays undefined. Under Vue 3/@vue/compat the
// forwarded slot always registers as a *present* slot function even when it
// renders nothing, flipping the child's slot-presence checks and rendering
// gated wrappers around empty content (first production hit: blank avatar
// tooltips on the repository pages, user_avatar_link.vue ->
// user_avatar_image.vue -> GlTooltip).
//
// Only the actual bug shape is flagged: a fallback-less outlet that is the
// sole content of the target slot. Outlets with fallback content or sibling
// content are exempt — there the child sees non-empty content on both
// runtimes, so presence checks agree.
//
// A fixed file also receives the `glSlotsMixin` import/registration (same
// machinery and constraints as `vue3-gl-slots`). Sites with a dynamic
// `:name` on the outlet, several outlets feeding one target slot, or a
// script the mixin cannot be injected into are reported without a fix.

import { defineTemplateBodyVisitor } from './utils/eslint_parsing_utils.mjs';
import {
  MIXIN_NAME,
  MIXIN_SOURCE,
  buildInjectionFixes,
  canInjectMixin,
} from './utils/gl_slots_mixin_injection.mjs';

export const MESSAGE =
  'Unconditionally forwarded <slot> registers as present on the child under Vue 3 even when it renders nothing. ' +
  'Guard the forwarding with a glSlots() presence check: <template v-if="glSlots().name" #target><slot name="name"></slot></template>.';

const HTML_TAGS = new Set(
  `a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption cite code col colgroup data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd label legend li link main map mark menu meta meter nav noscript object ol optgroup option output p param picture pre progress q rp rt ruby s samp section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title tr track u ul var video wbr transition keep-alive`.split(
    ' ',
  ),
);

const SVG_TAGS = new Set(
  'svg use path circle rect g line polyline polygon text defs clippath ellipse marker mask pattern tspan'.split(
    ' ',
  ),
);

const CONDITIONAL_DIRECTIVES = new Set(['if', 'else-if', 'else', 'for']);

// <component :is> is excluded: it can resolve to a native element, where a
// <template #default> child silently renders nothing.
const isComponentTag = (name) =>
  !HTML_TAGS.has(name.toLowerCase()) &&
  !SVG_TAGS.has(name.toLowerCase()) &&
  name !== 'slot' &&
  name !== 'template' &&
  name.toLowerCase() !== 'component';

const hasConditionalDirective = (el) =>
  (el.startTag?.attributes || []).some(
    (attribute) => attribute.directive && CONDITIONAL_DIRECTIVES.has(attribute.key.name.name),
  );

const getSlotDirective = (el) =>
  (el.startTag?.attributes || []).find(
    (attribute) => attribute.directive && attribute.key.name.name === 'slot',
  );

const isMeaningfulNode = (node) => {
  if (node.type === 'VElement') {
    // A named-slot <template> defines a different slot, not content of the
    // one being inspected.
    return !(node.name === 'template' && getSlotDirective(node));
  }
  if (node.type === 'VText') {
    return node.value.trim() !== '';
  }
  return node.type === 'VExpressionContainer';
};

const meaningfulChildren = (el) => (el.children || []).filter((node) => isMeaningfulNode(node));

// The forwarder's own slot the outlet reads: `<slot>` -> 'default',
// `<slot name="x">` -> 'x', `<slot :name="expr">` -> null (dynamic).
function getOutletName(slotElement) {
  const attributes = slotElement.startTag?.attributes || [];
  if (
    attributes.some(
      (attribute) =>
        attribute.directive &&
        attribute.key.name.name === 'bind' &&
        attribute.key.argument?.name === 'name',
    )
  ) {
    return null;
  }
  const nameAttribute = attributes.find(
    (attribute) => !attribute.directive && attribute.key.name === 'name',
  );
  return nameAttribute ? nameAttribute.value?.value || null : 'default';
}

const IDENTIFIER_RE = /^[A-Za-z_$][\w$]*$/;
const glSlotsAccess = (name) =>
  IDENTIFIER_RE.test(name) ? `glSlots().${name}` : `glSlots()['${name}']`;

export const vue3NoUnconditionalSlotForwarding = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Guard forwarded <slot> outlets with a glSlots() presence check so the child sees the same slot presence on Vue 2 and Vue 3',
    },
    fixable: 'code',
    schema: [],
  },
  create(context) {
    const { sourceCode } = context;

    let exportObject = null;
    let lastImport = null;
    let hasMixinImport = false;
    let injectionDone = false;

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
    };

    function report(slotElement, fix) {
      context.report({ node: slotElement.startTag, message: MESSAGE, fix });
    }

    function reportFixable(slotElement, buildGuardFixes) {
      report(slotElement, (fixer) => {
        const fixes = buildGuardFixes(fixer);
        if (!injectionDone) {
          injectionDone = true;
          fixes.push(
            ...buildInjectionFixes(fixer, { sourceCode, exportObject, lastImport, hasMixinImport }),
          );
        }
        return fixes;
      });
    }

    const templateVisitor = {
      "VElement[name='slot']": function checkSlotOutlet(slotElement) {
        // Fallback content: the child sees non-empty content on both
        // runtimes whether or not the caller provided the slot.
        if (meaningfulChildren(slotElement).length > 0) {
          return;
        }
        if (hasConditionalDirective(slotElement)) {
          return;
        }

        const { parent } = slotElement;
        if (!parent || parent.type !== 'VElement') {
          return;
        }

        const slotTemplate =
          parent.name === 'template' && getSlotDirective(parent) ? parent : null;
        const host = slotTemplate ? slotTemplate.parent : parent;
        if (!host || host.type !== 'VElement' || !isComponentTag(host.rawName || host.name)) {
          return;
        }
        if (slotTemplate && hasConditionalDirective(slotTemplate)) {
          return;
        }

        // Sibling content other than bare outlets keeps the target slot
        // non-empty on both runtimes — not a bug. Several bare outlets
        // feeding one target slot are still a bug but need a hand-written
        // combined guard, so they are reported without a fix.
        const container = slotTemplate || host;
        const siblings = meaningfulChildren(container);
        const isBareOutlet = (node) =>
          node.type === 'VElement' && node.name === 'slot' && meaningfulChildren(node).length === 0;
        if (siblings.some((node) => node !== slotElement && !isBareOutlet(node))) {
          return;
        }
        if (siblings.length !== 1) {
          report(slotElement);
          return;
        }

        const outletName = getOutletName(slotElement);
        // A v-slot directive on the host element itself (e.g.
        // `<child #default="scope">`) cannot coexist with the guarded
        // `<template #default>` the fix would add.
        const hostTakesSlotDirective = !slotTemplate && getSlotDirective(host);
        if (outletName === null || hostTakesSlotDirective || !canInjectMixin(exportObject)) {
          report(slotElement);
          return;
        }

        const guard = ` v-if="${glSlotsAccess(outletName)}"`;
        if (slotTemplate) {
          const insertAt = slotTemplate.startTag.range[0] + '<template'.length;
          reportFixable(slotElement, (fixer) => [
            fixer.insertTextAfterRange([insertAt, insertAt], guard),
          ]);
        } else {
          reportFixable(slotElement, (fixer) => [
            fixer.insertTextBefore(slotElement, `<template${guard} #default>`),
            fixer.insertTextAfter(slotElement, '</template>'),
          ]);
        }
      },
    };

    return defineTemplateBodyVisitor(context, templateVisitor, scriptVisitor);
  },
};
