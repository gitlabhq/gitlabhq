import { withServer } from 'storybook-mirage'; // eslint-disable-line import/no-unresolved
import Vue from 'vue';
import { createMockServer } from 'test_helpers/mock_server';
import translateMixin from '~/vue_shared/translate';

const stylesheetsRequireCtx = require.context(
  '../../app/assets/stylesheets',
  true,
  /(application|application_utilities|highlight\/themes\/white)\.scss$/,
);

window.gon = {
  user_color_scheme: 'white',
};
translateMixin(Vue);

stylesheetsRequireCtx('./application.scss');
stylesheetsRequireCtx('./application_utilities.scss');
stylesheetsRequireCtx('./highlight/themes/white.scss');

export const decorators = [withServer(createMockServer)];
