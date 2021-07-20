/* eslint-disable import/no-commonjs */
const IS_EE = require('../../config/helpers/is_ee_env');

module.exports = {
  stories: [
    '../../app/assets/javascripts/**/*.stories.js',
    IS_EE && '../../ee/app/assets/javascripts/**/*.stories.js',
  ].filter(Boolean),
  addons: ['@storybook/addon-essentials', '@storybook/addon-a11y'],
};
