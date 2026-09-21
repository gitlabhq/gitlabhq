import { RuleTester } from 'eslint';
import vueEslintParser from 'vue-eslint-parser';
import {
  vueMixinPairing,
  MESSAGE_IDS,
} from '../../../../../tooling/eslint-config/eslint-local-rules/vue_mixin_pairing';

const ruleTester = new RuleTester({
  languageOptions: {
    parser: vueEslintParser,
    ecmaVersion: 2022,
    sourceType: 'module',
  },
});

const FLAGS_SOURCE = '~/vue_shared/mixins/gl_feature_flags_mixin';

const options = [
  {
    mixins: [
      { source: '@gitlab/ui', imported: 'GlToastMixin', members: ['$toast'] },
      {
        source: FLAGS_SOURCE,
        imported: 'default',
        localName: 'glFeatureFlagsMixin',
        factory: true,
        members: ['glFeatures'],
      },
      {
        source: '~/tracking',
        imported: 'InternalEvents',
        factory: 'mixin',
        members: ['trackEvent'],
      },
      {
        source: '~/tracking/internal_events',
        imported: 'default',
        localName: 'InternalEvents',
        factory: 'mixin',
        members: ['trackEvent'],
      },
      {
        source: '~/vue_shared/mixins/timeago',
        imported: 'default',
        localName: 'timeagoMixin',
        members: ['timeFormatted', 'tooltipTitle'],
      },
      {
        source: '~/tracking',
        imported: 'default',
        localName: 'Tracking',
        factory: 'mixin',
        members: ['track', 'trackingCategory', 'trackingOptions'],
      },
    ],
  },
];

const missing = (member, registration, source) => ({
  messageId: MESSAGE_IDS.missing,
  data: { member, registration, source },
});

const unused = (registration, source, members) => ({
  messageId: MESSAGE_IDS.unused,
  data: { registration, source, members },
});

ruleTester.run('vue-mixin-pairing', vueMixinPairing, {
  valid: [
    {
      // Bare identifier registration paired with a script usage.
      filename: 'test.vue',
      options,
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
      // Factory registration paired with a template usage.
      filename: 'test.vue',
      options,
      code: `
<script>
import glFeatureFlagsMixin from '${FLAGS_SOURCE}';

export default {
  mixins: [glFeatureFlagsMixin()],
};
</script>
<template>
  <div v-if="glFeatures.foo">on</div>
</template>
      `,
    },
    {
      // The mixin is identified by its import, so a local alias still counts.
      filename: 'test.vue',
      options,
      code: `
<script>
import glFeatureFlagMixin from '${FLAGS_SOURCE}';

export default {
  mixins: [glFeatureFlagMixin()],
  computed: {
    enabled() {
      return this.glFeatures.foo;
    },
  },
};
</script>
      `,
    },
    {
      // Member-call factory with arguments, default import.
      filename: 'test.vue',
      options,
      code: `
<script>
import Tracking from '~/tracking';

export default {
  mixins: [Tracking.mixin({ label: 'x' })],
  methods: {
    onClick() {
      this.track('click');
    },
  },
};
</script>
      `,
    },
    {
      // Registration through a module-scope const alias.
      filename: 'test.vue',
      options,
      code: `
<script>
import { InternalEvents } from '~/tracking';

const trackingMixin = InternalEvents.mixin();

export default {
  mixins: [trackingMixin],
  mounted() {
    this.trackEvent('render');
  },
};
</script>
      `,
    },
    {
      // normalizeRender wrapper is looked through.
      filename: 'test.vue',
      options,
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  mixins: [GlToastMixin],
  render() {
    this.$toast.show('x');
    return null;
  },
});
</script>
      `,
    },
    {
      // A direct inject stands in for the flags mixin.
      filename: 'test.vue',
      options,
      code: `
<script>
export default {
  inject: ['glFeatures'],
  computed: {
    enabled() {
      return this.glFeatures.foo;
    },
  },
};
</script>
      `,
    },
    {
      // A member the component declares itself is not the mixin's.
      filename: 'test.vue',
      options,
      code: `
<script>
import Tracking from '~/tracking';

export default {
  mixins: [Tracking.mixin()],
  methods: {
    trackEvent(label) {
      this.track('clicked', { label });
    },
  },
};
</script>
<template>
  <button @click="trackEvent('a')">a</button>
</template>
      `,
    },
    {
      // A v-for alias that shares a member's name is a template variable,
      // not an instance read.
      filename: 'test.vue',
      options,
      code: `
<script>
export default {
  props: { tracks: { type: Array, required: true } },
};
</script>
<template>
  <ul>
    <li v-for="track in tracks" :key="track.id">{{ track.name }}</li>
  </ul>
</template>
      `,
    },
    {
      // Destructuring from `this` counts as a usage.
      filename: 'test.vue',
      options,
      code: `
<script>
import glFeatureFlagsMixin from '${FLAGS_SOURCE}';

export default {
  mixins: [glFeatureFlagsMixin()],
  methods: {
    check() {
      const { glFeatures } = this;
      return glFeatures.foo;
    },
  },
};
</script>
      `,
    },
    {
      // A relative import of the same module matches the entry.
      filename: '/repo/app/assets/javascripts/vue_shared/components/time_ago.vue',
      options,
      code: `
<script>
import timeagoMixin from '../mixins/timeago';

export default {
  mixins: [timeagoMixin],
  computed: {
    label() {
      return this.timeFormatted(this.time);
    },
  },
};
</script>
      `,
    },
    {
      // Two entries supply the same member; registering either is enough.
      filename: 'test.vue',
      options,
      code: `
<script>
import InternalEvents from '~/tracking/internal_events';

export default {
  mixins: [InternalEvents.mixin()],
  mounted() {
    this.trackEvent('render');
  },
};
</script>
      `,
    },
    {
      // Per-entry reportUnused off tolerates the stale registration.
      filename: 'test.vue',
      options: [
        {
          mixins: [
            {
              source: FLAGS_SOURCE,
              imported: 'default',
              localName: 'glFeatureFlagsMixin',
              factory: true,
              members: ['glFeatures'],
              reportUnused: false,
            },
          ],
        },
      ],
      code: `
<script>
import glFeatureFlagsMixin from '${FLAGS_SOURCE}';

export default {
  mixins: [glFeatureFlagsMixin()],
};
</script>
      `,
    },
    {
      // Global reportUnused off tolerates the stale registration.
      filename: 'test.vue',
      options: [{ ...options[0], reportUnused: false }],
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  mixins: [GlToastMixin],
};
</script>
      `,
    },
    {
      // Mixins outside the table are ignored.
      filename: 'test.vue',
      options,
      code: `
<script>
import otherMixin from './other_mixin';

export default {
  mixins: [otherMixin],
};
</script>
      `,
    },
    {
      // Plain JS module with nothing to pair.
      filename: 'test.js',
      options,
      code: `
export const foo = () => 1;
      `,
    },
  ],
  invalid: [
    {
      // Missing: extends the existing @gitlab/ui import, inserts `mixins`
      // below `components` as vue/order-in-components expects.
      filename: 'test.vue',
      options,
      code: `
<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'Foo',
  components: { GlButton },
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      errors: [missing('$toast', 'GlToastMixin', '@gitlab/ui')],
    },
    {
      // Missing default-import factory with no imports at all. Both template
      // usages are reported.
      filename: 'test.vue',
      options,
      code: `
<script>
export default {
  name: 'Foo',
  props: { foo: { type: String, required: true } },
};
</script>
<template>
  <div v-if="glFeatures.foo">{{ foo }}</div>
  <div v-else-if="glFeatures.bar">bar</div>
</template>
      `,
      errors: [
        missing('glFeatures', 'glFeatureFlagsMixin()', FLAGS_SOURCE),
        missing('glFeatures', 'glFeatureFlagsMixin()', FLAGS_SOURCE),
      ],
    },
    {
      // Missing member-call factory, import present, existing mixins array.
      filename: 'test.vue',
      options,
      code: `
<script>
import Tracking from '~/tracking';
import glFeatureFlagsMixin from '${FLAGS_SOURCE}';

export default {
  mixins: [glFeatureFlagsMixin()],
  methods: {
    onClick() {
      this.track('click');
      return this.glFeatures.foo;
    },
  },
};
</script>
      `,
      errors: [missing('track', 'Tracking.mixin()', '~/tracking')],
    },
    {
      // reportUnused off does not silence the missing half.
      filename: 'test.vue',
      options: [{ ...options[0], reportUnused: false }],
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
      `,
      errors: [missing('$toast', 'GlToastMixin', '@gitlab/ui')],
    },
    {
      // Missing, with the import name already bound to something else.
      filename: 'test.vue',
      options,
      code: `
<script>
import { Tracking } from './local_tracking';

export default {
  methods: {
    onClick() {
      Tracking.event('a');
      this.track('click');
    },
  },
};
</script>
      `,
      errors: [
        {
          messageId: MESSAGE_IDS.missing,
          data: { member: 'track', registration: 'Tracking.mixin()', source: '~/tracking' },
        },
      ],
    },
    {
      // Missing where `mixins` is not an array literal.
      filename: 'test.vue',
      options,
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';
import { sharedMixins } from './mixins';

export default {
  mixins: sharedMixins,
  methods: {
    save() {
      this.$toast.show('Saved');
    },
  },
};
</script>
      `,
      errors: [
        {
          messageId: MESSAGE_IDS.missing,
          data: { member: '$toast', registration: 'GlToastMixin', source: '@gitlab/ui' },
        },
      ],
    },
    {
      // Unused sole entry: the option and the import statement go.
      filename: 'test.vue',
      options,
      code: `
<script>
import { GlToastMixin } from '@gitlab/ui';

export default {
  name: 'Foo',
  mixins: [GlToastMixin],
  data() {
    return { a: 1 };
  },
};
</script>
      `,
      errors: [unused('GlToastMixin', '@gitlab/ui', "'$toast'")],
    },
    {
      // Unused last entry of two, import shared with a component.
      filename: 'test.vue',
      options,
      code: `
<script>
import { GlToastMixin, GlButton } from '@gitlab/ui';
import glFeatureFlagsMixin from '${FLAGS_SOURCE}';

export default {
  components: { GlButton },
  mixins: [glFeatureFlagsMixin(), GlToastMixin],
  computed: {
    enabled() {
      return this.glFeatures.foo;
    },
  },
};
</script>
      `,
      errors: [unused('GlToastMixin', '@gitlab/ui', "'$toast'")],
    },
    {
      // Unused first entry in a multi-line array: the following entry keeps
      // its line.
      filename: 'test.vue',
      options,
      code: `
<script>
import glFeatureFlagsMixin from '${FLAGS_SOURCE}';
import otherMixin from './other_mixin';

export default {
  mixins: [
    glFeatureFlagsMixin(),
    otherMixin,
  ],
};
</script>
      `,
      errors: [unused('glFeatureFlagsMixin()', FLAGS_SOURCE, "'glFeatures'")],
    },
    {
      // Unused registration through a const alias: entry, alias and import
      // all go.
      filename: 'test.vue',
      options,
      code: `
<script>
import { InternalEvents } from '~/tracking';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'Foo',
  mixins: [trackingMixin],
};
</script>
      `,
      errors: [unused('InternalEvents.mixin()', '~/tracking', "'trackEvent'")],
    },
    {
      // Unused, but the import is still used elsewhere: only the entry goes.
      filename: 'test.vue',
      options,
      code: `
<script>
import Tracking from '~/tracking';

export default {
  mixins: [Tracking.mixin()],
  methods: {
    onClick() {
      Tracking.event('cat', 'click');
    },
  },
};
</script>
      `,
      errors: [
        unused('Tracking.mixin()', '~/tracking', "'track', 'trackingCategory', 'trackingOptions'"),
      ],
    },
  ],
});
