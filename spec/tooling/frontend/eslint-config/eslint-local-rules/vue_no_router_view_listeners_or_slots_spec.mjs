import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  vueNoRouterViewListenersOrSlots,
  MESSAGE,
} from '../../../../../tooling/eslint-config/eslint-local-rules/vue_no_router_view_listeners_or_slots';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2020,
  },
});

ruleTester.run(
  'vue-no-router-view-listeners-or-slots',
  vueNoRouterViewListenersOrSlots,
  {
    valid: [
      {
        filename: 'test.vue',
        code: `<template><router-view /></template>`,
      },
      {
        filename: 'test.vue',
        code: `<template><router-view :foo="bar" /></template>`,
      },
      {
        filename: 'test.vue',
        code: `
          <template>
            <router-view-with-slot #default="{ Component }">
              <component :is="Component" @some-event="handler">
                <template #some-slot>content</template>
              </component>
            </router-view-with-slot>
          </template>
        `,
      },
      {
        // Whitespace-only text between tags (typical of multi-line
        // formatting) isn't real content.
        filename: 'test.vue',
        code: `
          <template>
            <router-view>
            </router-view>
          </template>
        `,
      },
    ],
    invalid: [
      {
        // Listener bound directly on router-view.
        filename: 'test.vue',
        code: `<template><router-view @some-event="handler" /></template>`,
        errors: [{ message: MESSAGE }],
      },
      {
        // Slot content passed directly to router-view.
        filename: 'test.vue',
        code: `<template><router-view><template #some-slot>content</template></router-view></template>`,
        errors: [{ message: MESSAGE }],
      },
      {
        // Default slot content.
        filename: 'test.vue',
        code: `<template><router-view><div>content</div></router-view></template>`,
        errors: [{ message: MESSAGE }],
      },
      {
        filename: 'test.vue',
        code: `<template><router-view>{{ text }}</router-view></template>`,
        errors: [{ message: MESSAGE }],
      },
      {
        filename: 'test.vue',
        code: `<template><router-view>some text</router-view></template>`,
        errors: [{ message: MESSAGE }],
      },
      {
        // v-slot on bare router-view: Vue Router 3 has no such API, so this
        // silently renders nothing under Vue 2.
        filename: 'test.vue',
        code: `
          <template>
            <router-view #default="{ Component }">
              <component :is="Component" />
            </router-view>
          </template>
        `,
        errors: [{ message: MESSAGE }],
      },
      {
        filename: 'test.vue',
        code: `<template><router-view #default="{ Component }" /></template>`,
        errors: [{ message: MESSAGE }],
      },
    ],
  },
);
