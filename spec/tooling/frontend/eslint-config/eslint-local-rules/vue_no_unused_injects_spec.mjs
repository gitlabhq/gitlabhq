import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import { vueNoUnusedInjects } from '../../../../../tooling/eslint-config/eslint-local-rules/vue_no_unused_injects';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2022,
    sourceType: 'module',
  },
});

ruleTester.run('vue-no-unused-injects', vueNoUnusedInjects, {
  valid: [
    {
      // Array-form inject used via `this.x` in a method.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          inject: ['fullPath'],
          methods: {
            doThing() {
              return this.fullPath;
            },
          },
        };
        </script>
      `,
    },
    {
      // Inject used only in the template.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          inject: ['emptyStateSvgPath'],
        };
        </script>
        <template>
          <gl-empty-state :svg-path="emptyStateSvgPath" />
        </template>
      `,
    },
    {
      // Object-form inject used in a computed property.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          inject: {
            isGroup: { default: false },
          },
          computed: {
            label() {
              return this.isGroup ? 'group' : 'project';
            },
          },
        };
        </script>
      `,
    },
    {
      // Not a Vue component: should not be linted.
      filename: 'not_a_vue_component.js',
      code: `
        const config = {
          inject: ['unused'],
        };
      `,
    },
    {
      // vuex/pinia map-helpers are collected by vue/no-unused-properties as
      // methods/computed regardless of `groups`; this rule must not flag them.
      filename: 'test.vue',
      code: `
        <script>
        import { mapActions } from 'pinia';
        export default {
          inject: ['used'],
          methods: {
            ...mapActions(useStore, ['fetchThing']),
            doThing() {
              return this.used;
            },
          },
        };
        </script>
      `,
    },
  ],

  invalid: [
    {
      // Array-form inject that is never referenced.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          inject: ['graphqlPath'],
          methods: {
            doThing() {
              return 1;
            },
          },
        };
        </script>
      `,
      errors: [{ messageId: 'unused' }],
    },
    {
      // Object-form inject that is never referenced.
      filename: 'test.vue',
      code: `
        <script>
        export default {
          inject: {
            searchPath: { default: '' },
          },
        };
        </script>
      `,
      errors: [{ messageId: 'unused' }],
    },
    {
      // An unused inject alongside map-helpers is still flagged (guards against the
      // group filter accidentally suppressing every report).
      filename: 'test.vue',
      code: `
        <script>
        import { mapActions } from 'pinia';
        export default {
          inject: ['unused'],
          methods: {
            ...mapActions(useStore, ['fetchThing']),
          },
        };
        </script>
      `,
      errors: [{ messageId: 'unused' }],
    },
  ],
});
