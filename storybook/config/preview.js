// eslint-disable-next-line import/no-extraneous-dependencies
import Vue from 'vue';
import translateMixin from '../../app/assets/javascripts/vue_shared/translate';

const stylesheetsRequireCtx = require.context(
  '../../app/assets/stylesheets',
  true,
  /(application|application_utilities)\.scss$/,
);

window.gon = {};
translateMixin(Vue);

stylesheetsRequireCtx('./application.scss');
stylesheetsRequireCtx('./application_utilities.scss');
