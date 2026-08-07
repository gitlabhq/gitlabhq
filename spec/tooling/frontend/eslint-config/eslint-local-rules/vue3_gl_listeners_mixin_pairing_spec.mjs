import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  vue3GlListenersMixinPairing,
  MISSING_MIXIN_MESSAGE,
  UNUSED_MIXIN_MESSAGE,
} from '../../../../../tooling/eslint-config/eslint-local-rules/vue3_gl_listeners_mixin_pairing';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2020,
  },
});

ruleTester.run('vue3-gl-listeners-mixin-pairing', vue3GlListenersMixinPairing, {
  valid: [
    {
      // Template usage paired with the mixin.
      filename: 'test.vue',
      code: `
        <script>
        import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

        export default {
          mixins: [glListenersMixin],
        };
        </script>
        <template>
          <div v-on="glListeners()"><slot></slot></div>
        </template>
      `,
    },
    {
      // Spread shape and glListener(name) reads count as usage.
      filename: 'test.vue',
      code: `
        <script>
        import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

        export default {
          mixins: [glListenersMixin],
          computed: {
            hasStepClick() {
              return Boolean(this.glListener('step-click'));
            },
          },
        };
        </script>
        <template>
          <div v-on="{ ...glListeners(), click: () => {} }">{{ hasStepClick }}</div>
        </template>
      `,
    },
    {
      // Call-wrapped default export (e.g. normalizeRender) registers the
      // mixin the same way.
      filename: 'test.vue',
      code: `
        <script>
        import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';
        import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

        export default normalizeRender({
          mixins: [glListenersMixin],
          render() {
            return this.glListeners();
          },
        });
        </script>
      `,
    },
    {
      // No usage and no mixin.
      filename: 'test.vue',
      code: `
        <script>
        export default {};
        </script>
        <template>
          <div><slot></slot></div>
        </template>
      `,
    },
  ],

  invalid: [
    {
      // Template usage without the mixin.
      filename: 'test.vue',
      code: `
        <script>
        export default {};
        </script>
        <template>
          <div v-on="glListeners()"><slot></slot></div>
        </template>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // glListener(name) alone is also a usage.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          computed: {
            hasStepClick() {
              return Boolean(this.glListener('step-click'));
            },
          },
        };
        </script>
        <template>
          <div>{{ hasStepClick }}</div>
        </template>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // Script usage without the mixin — also covers script-only files.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          render() {
            return this.glListeners();
          },
        };
        </script>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // Every usage is reported.
      filename: 'test.vue',
      code: `
        <script>
        export default {};
        </script>
        <template>
          <div>
            <div v-on="glListeners()"><slot></slot></div>
            <button v-on="glListeners()">go</button>
          </div>
        </template>
      `,
      errors: [MISSING_MIXIN_MESSAGE, MISSING_MIXIN_MESSAGE],
    },
    {
      // Mixin without any usage.
      filename: 'test.vue',
      code: `
        <script>
        import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

        export default {
          mixins: [glListenersMixin],
        };
        </script>
        <template>
          <div><slot></slot></div>
        </template>
      `,
      errors: [UNUSED_MIXIN_MESSAGE],
    },
    {
      // Mixin without usage, script-only file.
      filename: 'test.vue',
      code: `
        <script>
        import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';

        export default {
          mixins: [glListenersMixin],
          render() {
            return null;
          },
        };
        </script>
      `,
      errors: [UNUSED_MIXIN_MESSAGE],
    },
  ],
});
