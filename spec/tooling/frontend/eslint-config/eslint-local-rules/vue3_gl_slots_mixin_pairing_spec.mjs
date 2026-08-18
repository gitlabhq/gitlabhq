import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  vue3GlSlotsMixinPairing,
  MISSING_MIXIN_MESSAGE,
  UNUSED_MIXIN_MESSAGE,
} from '../../../../../tooling/eslint-config/eslint-local-rules/vue3_gl_slots_mixin_pairing';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2020,
  },
});

ruleTester.run('vue3-gl-slots-mixin-pairing', vue3GlSlotsMixinPairing, {
  valid: [
    {
      // Template usage paired with the mixin.
      filename: 'test.vue',
      code: `
        <script>
        import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

        export default {
          mixins: [glSlotsMixin],
        };
        </script>
        <template>
          <div v-if="glSlots().header"><slot name="header"></slot></div>
        </template>
      `,
    },
    {
      // Script usage paired with the mixin.
      filename: 'test.vue',
      code: `
        <script>
        import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

        export default {
          mixins: [glSlotsMixin],
          computed: {
            hasHeader() {
              return Boolean(this.glSlots().header);
            },
          },
        };
        </script>
        <template>
          <div>{{ hasHeader }}</div>
        </template>
      `,
    },
    {
      // Call-wrapped default export (e.g. normalizeRender) registers the
      // mixin the same way.
      filename: 'test.vue',
      code: `
        <script>
        import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
        import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

        export default normalizeRender({
          mixins: [glSlotsMixin],
          render() {
            return this.glSlots().default?.();
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
          <div v-if="glSlots().header"><slot name="header"></slot></div>
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
            return this.glSlots().default?.();
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
            <div v-if="glSlots().header"><slot name="header"></slot></div>
            <div v-if="glSlots().footer"><slot name="footer"></slot></div>
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
        import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

        export default {
          mixins: [glSlotsMixin],
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
        import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

        export default {
          mixins: [glSlotsMixin],
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
