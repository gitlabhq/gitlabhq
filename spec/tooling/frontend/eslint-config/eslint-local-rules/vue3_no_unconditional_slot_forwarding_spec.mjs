import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  vue3NoUnconditionalSlotForwarding,
  MESSAGE,
} from '../../../../../tooling/eslint-config/eslint-local-rules/vue3_no_unconditional_slot_forwarding';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2020,
  },
});

const MIXIN_IMPORT = `import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';`;

ruleTester.run('vue3-no-unconditional-slot-forwarding', vue3NoUnconditionalSlotForwarding, {
  valid: [
    {
      // Already guarded via wrapping template.
      filename: 'test.vue',
      code: `
        <script>
        ${MIXIN_IMPORT}
        export default { mixins: [glSlotsMixin] };
        </script>
        <template>
          <child-component>
            <template v-if="glSlots().default" #default><slot></slot></template>
          </child-component>
        </template>
      `,
    },
    {
      // Guard directly on the outlet.
      filename: 'test.vue',
      code: `
        <script>
        ${MIXIN_IMPORT}
        export default { mixins: [glSlotsMixin] };
        </script>
        <template>
          <child-component><slot v-if="glSlots().default"></slot></child-component>
        </template>
      `,
    },
    {
      // Fallback content: child sees non-empty content on both runtimes.
      filename: 'test.vue',
      code: `
        <script>export default {};</script>
        <template>
          <child-component><slot>fallback</slot></child-component>
        </template>
      `,
    },
    {
      // Sibling content keeps the target slot non-empty on both runtimes.
      filename: 'test.vue',
      code: `
        <script>export default {};</script>
        <template>
          <child-component><span>real content</span><slot></slot></child-component>
        </template>
      `,
    },
    {
      // Outlet inside a plain HTML element is the forwarder's own rendering,
      // not slot content handed to a component.
      filename: 'test.vue',
      code: `
        <script>export default {};</script>
        <template>
          <child-component><div><slot></slot></div></child-component>
        </template>
      `,
    },
    {
      // Outlet not inside any component.
      filename: 'test.vue',
      code: `
        <script>export default {};</script>
        <template>
          <div><slot></slot></div>
        </template>
      `,
    },
    {
      // <component :is> can resolve to a native element, where a wrapped
      // <template #default> child silently renders nothing.
      filename: 'test.vue',
      code: `
        <script>export default {};</script>
        <template>
          <component :is="wtag"><slot></slot></component>
        </template>
      `,
    },
  ],
  invalid: [
    {
      // Bare default forward (the user_avatar_link.vue shape).
      filename: 'test.vue',
      code: `
<script>
import ChildComponent from './child_component.vue';
export default {
  components: { ChildComponent },
};
</script>
<template>
  <child-component><slot></slot></child-component>
</template>
      `,
      output: `
<script>
import ChildComponent from './child_component.vue';
${MIXIN_IMPORT}
export default {
  components: { ChildComponent },
  mixins: [glSlotsMixin],
};
</script>
<template>
  <child-component><template v-if="glSlots().default" #default><slot></slot></template></child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
    {
      // Named outlet forwarded into the child's default slot.
      filename: 'test.vue',
      code: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component><slot name="icon"></slot></child-component>
</template>
      `,
      output: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component><template v-if="glSlots().icon" #default><slot name="icon"></slot></template></child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
    {
      // Existing named-slot template wrapper: guard lands on the template.
      filename: 'test.vue',
      code: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component>
    <template #footer><slot name="footer"></slot></template>
  </child-component>
</template>
      `,
      output: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component>
    <template v-if="glSlots().footer" #footer><slot name="footer"></slot></template>
  </child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
    {
      // Slot names that are not identifier-safe use bracket access.
      filename: 'test.vue',
      code: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component>
    <template #avatar-badge><slot name="avatar-badge"></slot></template>
  </child-component>
</template>
      `,
      output: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component>
    <template v-if="glSlots()['avatar-badge']" #avatar-badge><slot name="avatar-badge"></slot></template>
  </child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
    {
      // v-slot directive on the host element cannot coexist with the guarded
      // template the fix would add: reported without a fix.
      filename: 'test.vue',
      code: `
<script>export default {};</script>
<template>
  <child-component #default="{ scope }"><slot :scope="scope"></slot></child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
    {
      // Dynamic outlet name: reported without a fix.
      filename: 'test.vue',
      code: `
<script>export default {};</script>
<template>
  <child-component><slot :name="dynamicName"></slot></child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
    {
      // Several bare outlets feeding one target slot: reported without a fix
      // (needs a hand-written combined guard).
      filename: 'test.vue',
      code: `
<script>export default {};</script>
<template>
  <child-component><slot name="a"></slot><slot name="b"></slot></child-component>
</template>
      `,
      errors: [{ message: MESSAGE }, { message: MESSAGE }],
    },
    {
      // Scoped slot props on the outlet survive the wrap.
      filename: 'test.vue',
      code: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component><slot :item="item"></slot></child-component>
</template>
      `,
      output: `
<script>
${MIXIN_IMPORT}
export default { mixins: [glSlotsMixin] };
</script>
<template>
  <child-component><template v-if="glSlots().default" #default><slot :item="item"></slot></template></child-component>
</template>
      `,
      errors: [{ message: MESSAGE }],
    },
  ],
});
