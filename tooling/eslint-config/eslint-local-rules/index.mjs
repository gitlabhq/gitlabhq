import { requireValidHelpPagePath } from './require_valid_help_page_path.mjs';
import { vueRequireValidHelpPageLinkComponent } from './vue_require_valid_help_page_link_component.mjs';
import { graphqlRequireFeatureCategory } from './graphql_require_feature_category.mjs';
import { graphqlRequireValidUrgency } from './graphql_require_valid_urgency.mjs';
import { vueRequireVueConstructorName } from './vue_require_vue_constructor_name.mjs';
import { noOrphanedFeatureFlagReferences } from './no_orphaned_feature_flag_references.mjs';
import { noWebUrl } from './no_web_url.mjs';
import { vueNoWebUrl } from './vue_no_web_url.mjs';
import { noMixedJestAliases } from './no_mixed_jest_aliases.mjs';
import { pageEntrypointMustExecute } from './page_entrypoint_must_execute.mjs';
import { noApolloMock } from './no_apollo_mock.mjs';
import { vueNoUnusedInjects } from './vue_no_unused_injects.mjs';
import { vue3FindComponentUpgrade } from './vue3_find_component_upgrade.mjs';
import { vue3GlSlots } from './vue3_gl_slots.mjs';
import { vue3GlSlotsMixinPairing } from './vue3_gl_slots_mixin_pairing.mjs';
import { vue3InitVueApp } from './vue3_init_vue_app.mjs';
import { vue3NoUnconditionalSlotForwarding } from './vue3_no_unconditional_slot_forwarding.mjs';
import { vue3GlListeners } from './vue3_gl_listeners.mjs';
import { vue3GlListenersMixinPairing } from './vue3_gl_listeners_mixin_pairing.mjs';
import { glToastMixinRule } from './gl_toast_mixin.mjs';

export const eslintLocalRules = {
  rules: {
    'require-valid-help-page-path': requireValidHelpPagePath,
    'vue-require-valid-help-page-link-component': vueRequireValidHelpPageLinkComponent,
    'graphql-require-feature-category': graphqlRequireFeatureCategory,
    'graphql-require-valid-urgency': graphqlRequireValidUrgency,
    'vue-require-vue-constructor-name': vueRequireVueConstructorName,
    'no-orphaned-feature-flag-references': noOrphanedFeatureFlagReferences,
    'no-web-url': noWebUrl,
    'vue-no-web-url': vueNoWebUrl,
    'no-mixed-jest-aliases': noMixedJestAliases,
    'page-entrypoint-must-execute': pageEntrypointMustExecute,
    'no-apollo-mock': noApolloMock,
    'vue-no-unused-injects': vueNoUnusedInjects,
    'vue3-find-component-upgrade': vue3FindComponentUpgrade,
    'vue3-gl-slots': vue3GlSlots,
    'vue3-gl-slots-mixin-pairing': vue3GlSlotsMixinPairing,
    'vue3-init-vue-app': vue3InitVueApp,
    'vue3-no-unconditional-slot-forwarding': vue3NoUnconditionalSlotForwarding,
    'vue3-gl-listeners': vue3GlListeners,
    'vue3-gl-listeners-mixin-pairing': vue3GlListenersMixinPairing,
    'gl-toast-mixin': glToastMixinRule,
  },
};
