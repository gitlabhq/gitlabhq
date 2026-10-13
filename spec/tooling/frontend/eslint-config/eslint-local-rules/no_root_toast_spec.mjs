import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  noRootToast,
  ROOT_TOAST_MESSAGE,
} from '../../../../../tooling/eslint-config/eslint-local-rules/no_root_toast';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2022,
    sourceType: 'module',
  },
});

ruleTester.run('no-root-toast', noRootToast, {
  valid: [
    {
      // A local `$toast` read is the pairing rule's business, not this one's.
      filename: 'test.vue',
      code: `
<script>
export default {
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
<template>
  <button @click="$toast.show('x')">x</button>
</template>
      `,
    },
    {
      // Other `$root` reads are fine.
      filename: 'test.vue',
      code: `
<script>
export default {
  computed: {
    rootId() {
      return this.$root.$el.id;
    },
  },
};
</script>
      `,
    },
  ],
  invalid: [
    {
      // Script read.
      filename: 'test.vue',
      code: `
<script>
export default {
  methods: {
    save() {
      this.$root.$toast.show('Saved');
    },
  },
};
</script>
      `,
      errors: [ROOT_TOAST_MESSAGE],
    },
    {
      // Template read.
      filename: 'test.vue',
      code: `
<script>
export default {};
</script>
<template>
  <button @click="$root.$toast.show('x')">x</button>
</template>
      `,
      errors: [ROOT_TOAST_MESSAGE],
    },
    {
      // Plain JS file.
      filename: 'test.js',
      code: `
export function notify(vm) {
  vm.$root.$toast.show('x');
}
      `,
      errors: [ROOT_TOAST_MESSAGE],
    },
  ],
});
