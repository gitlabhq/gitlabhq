import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import { vueNoWebUrl } from '../../../../../tooling/eslint-config/eslint-local-rules/vue_no_web_url';
import { ERROR_MESSAGE } from '../../../../../tooling/eslint-config/eslint-local-rules/utils/no_web_url_utils';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2020,
  },
});

ruleTester.run('vue-no-web-url', vueNoWebUrl, {
  valid: [
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ item.webPath }}</div>
        </template>
      `,
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <a :href="item.web_path">Link</a>
        </template>
      `,
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ project.webPath }}</div>
        </template>
      `,
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ project.otherProperty }}</div>
        </template>
      `,
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ project.nested.webPath }}</div>
        </template>
      `,
    },
    {
      filename: 'not_a_vue_component.js',
      code: `
        class Foo {
          foo() {
            return this.item.webUrl;
          }
        }
      `,
    },
  ],

  invalid: [
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ item.webUrl }}</div>
        </template>
      `,
      errors: [ERROR_MESSAGE],
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <a :href="item.web_url">Link</a>
        </template>
      `,
      errors: [ERROR_MESSAGE],
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ project['webUrl'] }}</div>
        </template>
      `,
      errors: [ERROR_MESSAGE],
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ project.nested.webUrl }}</div>
        </template>
      `,
      errors: [ERROR_MESSAGE],
    },
    {
      filename: 'test.vue',
      code: `
        <template>
          <div>{{ project.nested.web_url }}</div>
        </template>
      `,
      errors: [ERROR_MESSAGE],
    },
  ],
});
