import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  glToastMixinRule,
  MISSING_MIXIN_MESSAGE,
  UNUSED_MIXIN_MESSAGE,
  ROOT_TOAST_MESSAGE,
  MANUAL_FIX_MESSAGE,
} from '../../../../../tooling/eslint-config/eslint-local-rules/gl_toast_mixin';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2022,
    sourceType: 'module',
  },
});

ruleTester.run('gl-toast-mixin', glToastMixinRule, {
  valid: [
    {
      // Script usage paired with the mixin.
      filename: 'test.vue',
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
    },
    {
      // Template usage paired with the mixin.
      filename: 'test.vue',
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
};
</script>
<template>
  <button @click="$toast.show('Saved')">Save</button>
</template>
      `,
    },
    {
      // Call-wrapped default export.
      filename: 'test.vue',
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  mixins: [GlToastMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
});
</script>
      `,
    },
    {
      // A mixin file is itself a component options object, so it can declare
      // the dependency the same way.
      filename: 'bulk_mutations.js',
      code: `
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
  methods: {
    notify() {
      this.$toast.show('Done');
    },
  },
};
      `,
    },
    {
      // Neither usage nor mixin.
      filename: 'test.vue',
      code: `
<script>
export default {};
</script>
<template>
  <div>Nothing to see</div>
</template>
      `,
    },
    {
      // `$toast` on something that is not the component is out of scope: the
      // global_toast helper drives its own detached instance.
      filename: 'global_toast.js',
      code: `
import Vue from 'vue';

const instance = new Vue();

export default function showGlobalToast(...args) {
  return instance.$toast.show(...args);
}
      `,
    },
  ],

  invalid: [
    {
      // Adds both the import and the mixins option.
      filename: 'test.vue',
      code: `
<script>
import { __ } from '~/locale';

export default {
  name: 'MyComponent',
  methods: {
    save() {
      this.$toast.show(__('Saved'));
    },
  },
};
</script>
      `,
      output: `
<script>
import { __ } from '~/locale';
import { GlToastMixin } from '@gitlab/ui';

export default {
  name: 'MyComponent',
  mixins: [GlToastMixin],
  methods: {
    save() {
      this.$toast.show(__('Saved'));
    },
  },
};
</script>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // The common shape: the file already imports from @gitlab/ui, so the
      // mixin joins that statement instead of adding a duplicate import.
      filename: 'test.vue',
      code: `
<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'MyComponent',
  components: {
    GlButton,
  },
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      output: `
<script>
import { GlButton, GlToastMixin } from '@gitlab/ui';

export default {
  name: 'MyComponent',
  components: {
    GlButton,
  },
  mixins: [GlToastMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // `vue/order-in-components` wants `mixins` below `components` and
      // `directives`, and cannot autofix, so the insertion point matters.
      filename: 'test.vue',
      code: `
<script>
export default {
  name: 'MyComponent',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      output: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  name: 'MyComponent',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  mixins: [GlToastMixin],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // Appends to an existing mixins array.
      filename: 'test.vue',
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  mixins: [timeagoMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      output: `
<script>
import { GlToastMixin } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  mixins: [timeagoMixin, GlToastMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // Template-only usage. No file uses this today, which is exactly why it
      // is pinned here.
      filename: 'test.vue',
      code: `
<script>
export default {
  name: 'MyComponent',
};
</script>
<template>
  <button @click="$toast.show('Saved')">Save</button>
</template>
      `,
      output: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  name: 'MyComponent',
  mixins: [GlToastMixin],
};
</script>
<template>
  <button @click="$toast.show('Saved')">Save</button>
</template>
      `,
      errors: [MISSING_MIXIN_MESSAGE],
    },
    {
      // A root read in a template is reported without a fix and pulls in no
      // mixin. The `$toast` half of `$root.$toast` matches the plain-identifier
      // selector as well, so it has to be excluded there.
      filename: 'test.vue',
      code: `
<script>
export default {
  name: 'MyComponent',
};
</script>
<template>
  <button @click="$root.$toast.show('Saved')">Save</button>
</template>
      `,
      output: null,
      errors: [ROOT_TOAST_MESSAGE],
    },
    {
      // Every usage is reported, but only one registration is added.
      filename: 'test.vue',
      code: `
<script>
export default {
  methods: {
    save() {
      this.$toast.show('Saved');
    },
    remove() {
      this.$toast.show('Removed');
    },
  },
};
</script>
      `,
      output: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
    remove() {
      this.$toast.show('Removed');
    },
  },
};
</script>
      `,
      errors: [MISSING_MIXIN_MESSAGE, MISSING_MIXIN_MESSAGE],
    },
    {
      // $root.$toast is reported but never autofixed, and it does not count as a
      // usage the mixin would satisfy -- so no mixin is added here. Optional
      // chaining is still recognised as a root read.
      filename: 'test.vue',
      code: `
<script>
export default {
  methods: {
    save() {
      this.$root.$toast?.show('Saved');
    },
  },
};
</script>
      `,
      output: null,
      errors: [ROOT_TOAST_MESSAGE],
    },
    {
      // A real this.$toast next to a $root read: the mixin is added for the
      // former, while the latter is left alone for a human to convert.
      filename: 'test.vue',
      code: `
<script>
export default {
  methods: {
    save() {
      this.$toast.show('Saved');
    },
    close() {
      this.$root.$toast.show('Closed');
    },
  },
};
</script>
      `,
      output: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
  methods: {
    save() {
      this.$toast.show('Saved');
    },
    close() {
      this.$root.$toast.show('Closed');
    },
  },
};
</script>
      `,
      errors: [MISSING_MIXIN_MESSAGE, ROOT_TOAST_MESSAGE],
    },
    {
      // Declared but unused: the option and the import both go.
      filename: 'test.vue',
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
  name: 'MyComponent',
};
</script>
      `,
      output: `
<script>
export default {
  name: 'MyComponent',
};
</script>
      `,
      errors: [UNUSED_MIXIN_MESSAGE],
    },
    {
      // Declared but unused alongside another mixin: only this entry goes, and
      // the shared import line is left alone.
      filename: 'test.vue',
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  mixins: [timeagoMixin, GlToastMixin],
};
</script>
      `,
      output: `
<script>
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  mixins: [timeagoMixin],
};
</script>
      `,
      errors: [UNUSED_MIXIN_MESSAGE],
    },
    {
      // Declared but unused, sharing the @gitlab/ui import with a component:
      // only the specifier goes, and no trailing comma is left behind.
      filename: 'test.vue',
      code: `
<script>
import { GlButton, GlToastMixin } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  mixins: [GlToastMixin],
};
</script>
      `,
      output: `
<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
};
</script>
      `,
      errors: [UNUSED_MIXIN_MESSAGE],
    },
    {
      // No options object to attach the mixin to, so the fix is left to a human.
      filename: 'pipelines_index.js',
      code: `
import Vue from 'vue';

export default () =>
  new Vue({
    methods: {
      onDeleted() {
        this.$toast.show('The pipeline has been deleted');
      },
    },
  });
      `,
      errors: [MANUAL_FIX_MESSAGE],
    },
  ],
});
