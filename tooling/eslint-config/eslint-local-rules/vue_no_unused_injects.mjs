import vueNoUnusedProperties from 'eslint-plugin-vue/lib/rules/no-unused-properties.js';

/**
 * Disallow unused `inject` declarations in Vue components.
 *
 * `vue/no-unused-properties` already knows how to detect unused `inject`
 * entries internally, but its schema only allows the `groups` option to contain
 * `props`/`data`/`asyncData`/`computed`/`methods`/`setup`. This rule delegates to
 * it, forcing `groups: ['inject']` from inside `create()` so we reuse all of its
 * battle-tested detection (template-only usage, `<script setup>`, `this.foo`,
 * destructuring, etc.).
 */
export const vueNoUnusedInjects = {
  meta: {
    // Spread the upstream meta so `context.report` can resolve `messageId: 'unused'`
    // against this rule's `messages`.
    ...vueNoUnusedProperties.meta,
    docs: {
      ...vueNoUnusedProperties.meta.docs,
      description: 'disallow unused `inject` declarations in Vue components',
    },
    // No user-facing options: the group is fixed to `inject`.
    schema: [],
  },
  create(context) {
    // Force `groups: ['inject']` without exposing options to consumers, and only
    // forward `inject` reports.
    const patchedContext = Object.create(context, {
      options: { value: [{ groups: ['inject'] }], enumerable: true },
      report: {
        enumerable: true,
        value(descriptor) {
          if (descriptor.data?.group !== 'inject') return;
          context.report(descriptor);
        },
      },
    });

    return vueNoUnusedProperties.create(patchedContext);
  },
};
