// Some modules read window.gon on initialization thus we need to define this object before anything else
import './gon';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex'; // eslint-disable-line no-restricted-imports
import translateMixin from '~/vue_shared/translate';
import logoWithBlackText from '../static/_logo_with_black_text.svg';
import logoWithWhiteText from '../static/_logo_with_white_text.svg';
import { initializeGitLabAPIAccess } from './addons/gitlab_api_access/preview';

const stylesheetsRequireCtx = require.context(
  '../../app/assets/stylesheets',
  true,
  /(application|application_utilities|highlight\/themes\/white|lazy_bundles\/gridstack)\.scss$/,
);

initializeGitLabAPIAccess();

translateMixin(Vue);
Vue.use(VueApollo);
Vue.use(Vuex);

stylesheetsRequireCtx('./application.scss');
stylesheetsRequireCtx('./application_utilities.scss');
import('../../app/assets/builds/tailwind.css');
stylesheetsRequireCtx('./highlight/themes/white.scss');
stylesheetsRequireCtx('./lazy_bundles/gridstack.scss');

export const theme = {
  brandTitle: 'GitLab (Product)',
  brandUrl: 'https://gitlab.com/gitlab-org/gitlab',
};

export const parameters = {
  darkMode: {
    current: 'light',
    stylePreview: true,
    classTarget: 'html',
    darkClass: 'gl-dark',
    dark: {
      ...theme,
      brandImage: logoWithWhiteText,
    },
    light: {
      ...theme,
      brandImage: logoWithBlackText,
    },
  },
  a11y: {},
  viewport: {
    viewports: {
      breakpointSmall: {
        name: 'Breakpoint small (width: 320px)',
        styles: {
          height: '568px',
          width: '320px',
        },
      },
      breakpointMedium: {
        name: 'Breakpoint medium (width: 768px)',
        styles: {
          height: '1024px',
          width: '768px',
        },
      },
      breakpointLarge: {
        name: 'Breakpoint large (width: 1024px)',
        styles: {
          height: '768px',
          width: '1024px',
        },
      },
      breakpointExtraLarge: {
        name: 'Breakpoint extra large (width: 1280px)',
        styles: {
          height: '800px',
          width: '1280px',
        },
      },
    },
  },
};
