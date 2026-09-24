import { requireValidHelpPagePath } from './require_valid_help_page_path.mjs';
import { vueRequireValidHelpPageLinkComponent } from './vue_require_valid_help_page_link_component.mjs';
import { graphqlRequireFeatureCategory } from './graphql_require_feature_category.mjs';
import { graphqlRequireValidUrgency } from './graphql_require_valid_urgency.mjs';
import { noOrphanedFeatureFlagReferences } from './no_orphaned_feature_flag_references.mjs';
import { noWebUrl } from './no_web_url.mjs';
import { vueNoWebUrl } from './vue_no_web_url.mjs';
import { noMixedJestAliases } from './no_mixed_jest_aliases.mjs';
import { pageEntrypointMustExecute } from './page_entrypoint_must_execute.mjs';
import { noApolloMock } from './no_apollo_mock.mjs';
import { vueNoRouterViewListenersOrSlots } from './vue_no_router_view_listeners_or_slots.mjs';
import { vue3FindComponentUpgrade } from './vue3_find_component_upgrade.mjs';
import { vueMixinPairing } from './vue_mixin_pairing.mjs';
import { vue3InitVueApp } from './vue3_init_vue_app.mjs';
import { vue3NoUnconditionalSlotForwarding } from './vue3_no_unconditional_slot_forwarding.mjs';
import { vue3GlListeners } from './vue3_gl_listeners.mjs';
import { noRootToast } from './no_root_toast.mjs';

export const eslintLocalRules = {
  rules: {
    'require-valid-help-page-path': requireValidHelpPagePath,
    'vue-require-valid-help-page-link-component': vueRequireValidHelpPageLinkComponent,
    'graphql-require-feature-category': graphqlRequireFeatureCategory,
    'graphql-require-valid-urgency': graphqlRequireValidUrgency,
    'no-orphaned-feature-flag-references': noOrphanedFeatureFlagReferences,
    'no-web-url': noWebUrl,
    'vue-no-web-url': vueNoWebUrl,
    'no-mixed-jest-aliases': noMixedJestAliases,
    'page-entrypoint-must-execute': pageEntrypointMustExecute,
    'no-apollo-mock': noApolloMock,
    'vue-no-router-view-listeners-or-slots': vueNoRouterViewListenersOrSlots,
    'vue3-find-component-upgrade': vue3FindComponentUpgrade,
    'vue-mixin-pairing': vueMixinPairing,
    'vue3-init-vue-app': vue3InitVueApp,
    'vue3-no-unconditional-slot-forwarding': vue3NoUnconditionalSlotForwarding,
    'vue3-gl-listeners': vue3GlListeners,
    'no-root-toast': noRootToast,
  },
};
