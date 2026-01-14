import { requireValidHelpPagePath } from './require_valid_help_page_path.mjs';
import { vueRequireValidHelpPageLinkComponent } from './vue_require_valid_help_page_link_component.mjs';
import { graphqlRequireFeatureCategory } from './graphql_require_feature_category.mjs';
import { graphqlRequireValidUrgency } from './graphql_require_valid_urgency.mjs';

export const eslintLocalRules = {
  rules: {
    'require-valid-help-page-path': requireValidHelpPagePath,
    'vue-require-valid-help-page-link-component': vueRequireValidHelpPageLinkComponent,
    'graphql-require-feature-category': graphqlRequireFeatureCategory,
    'graphql-require-valid-urgency': graphqlRequireValidUrgency,
  },
};
