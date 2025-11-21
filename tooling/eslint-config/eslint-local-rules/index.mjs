import { requireValidHelpPagePath } from './require_valid_help_page_path.mjs';
import { vueRequireValidHelpPageLinkComponent } from './vue_require_valid_help_page_link_component.mjs';

export const eslintLocalRules = {
  rules: {
    'require-valid-help-page-path': requireValidHelpPagePath,
    'vue-require-valid-help-page-link-component': vueRequireValidHelpPageLinkComponent,
  },
};
