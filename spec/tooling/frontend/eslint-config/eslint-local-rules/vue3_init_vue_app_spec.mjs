import { RuleTester } from 'eslint';
import { vue3InitVueApp } from '../../../../../tooling/eslint-config/eslint-local-rules/vue3_init_vue_app.mjs';

const ruleTester = new RuleTester({
  languageOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
});

const HELPER_IMPORT = `import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';`;

ruleTester.run('vue3-init-vue-app', vue3InitVueApp, {
  valid: [
    // `Vue` that is not the default import from 'vue' is not ours to convert
    {
      code: `import Vue from 'not-vue';
new Vue({ el: '#app', render(h) { return h(App); } });`,
    },
    // Unresolvable Vue identifier (e.g. a global) is left alone
    {
      code: `new Vue({ el: '#app', render(h) { return h(App); } });`,
    },
    // Already-converted code
    {
      code: `${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', component: App });`,
    },
  ],

  invalid: [
    // The dominant bootstrap shape: el + name + render(h) => h(App)
    {
      code: `import Vue from 'vue';
import App from './app.vue';
export const init = () => {
  const el = document.querySelector('#app');
  if (!el) return false;
  return new Vue({ el, name: 'MyApp', render(h) { return h(App); } });
};`,
      output: `import Vue from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
export const init = () => {
  const el = document.querySelector('#app');
  if (!el) return false;
  return initVueApp({ el, name: 'MyApp', component: App });
};`,
      errors: [{ messageId: 'useInitVueApp' }],
    },
    // Props, container options and arrow renders are lifted
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({
  el: '#app',
  apolloProvider,
  store,
  provide: { fullPath },
  render: (createElement) => createElement(App, { props: { userId: 1 } }),
});`,
      output: `import Vue from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', apolloProvider, store, provide: { fullPath }, component: App, props: { userId: 1 } });`,
      errors: [{ messageId: 'useInitVueApp' }],
    },
    // Member-expression components and shorthand props survive verbatim
    {
      code: `import Vue from 'vue';
import * as components from './components';
const props = { userId: 1 };
new Vue({ el: '#app', router, pinia, render(h) { return h(components.App, { props }); } });`,
      output: `import Vue from 'vue';
${HELPER_IMPORT}
import * as components from './components';
const props = { userId: 1 };
initVueApp({ el: '#app', router, pinia, component: components.App, props });`,
      errors: [{ messageId: 'useInitVueApp' }],
    },
    // The helper import is not duplicated when it is already there
    {
      code: `import Vue from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
new Vue({ el: '#app', render(h) { return h(App); } });
export const keepVue = () => Vue.version;`,
      output: `import Vue from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', component: App });
export const keepVue = () => Vue.version;`,
      errors: [{ messageId: 'useInitVueApp' }],
    },
    // Once converted, a now-unused `Vue` default import is removed
    {
      code: `import Vue from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', component: App });`,
      output: `${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', component: App });`,
      errors: [{ messageId: 'removeUnusedVueImport' }],
    },
    {
      code: `import Vue, { nextTick } from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', component: App });
export { nextTick };`,
      output: `import { nextTick } from 'vue';
${HELPER_IMPORT}
import App from './app.vue';
initVueApp({ el: '#app', component: App });
export { nextTick };`,
      errors: [{ messageId: 'removeUnusedVueImport' }],
    },

    // --- residual shapes: reported, not fixed ---

    // Event-bus instances
    {
      code: `import Vue from 'vue';
export const bus = new Vue();`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    // $mount() chains
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({ render(h) { return h(App); } }).$mount('#app');`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    // Options outside the helper surface (data, template, components, ...)
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({ el: '#app', data: { visible: true }, render(h) { return h(App); } });`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({ el: '#app', components: { App }, template: '<app />' });`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    // Renders with children or Vue 2 data objects
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({ el: '#app', render(h) { return h(App, [h('div')]); } });`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({ el: '#app', render(h) { return h(App, { on: { click: onClick } }); } });`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    // Renders whose moved expressions depend on `this`
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({ el: '#app', render(h) { return h(App, { props: { value: this.value } }); } });`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
    // Comments that the rewrite would drop
    {
      code: `import Vue from 'vue';
import App from './app.vue';
new Vue({
  el: '#app',
  render(h) {
    // some important note about this render
    return h(App);
  },
});`,
      output: null,
      errors: [{ messageId: 'useInitVueAppManual' }],
    },
  ],
});
