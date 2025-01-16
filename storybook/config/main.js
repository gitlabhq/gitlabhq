const path = require('path');
const IS_EE = require('../../config/helpers/is_ee_env');

module.exports = {
  stories: [
    '../../app/assets/javascripts/**/*.stories.js',
    IS_EE && '../../ee/app/assets/javascripts/**/*.stories.js',
  ].filter(Boolean),
  addons: [
    '@storybook/addon-docs',
    '@storybook/addon-essentials',
    '@storybook/addon-a11y',
    '@storybook/addon-viewport',
    'storybook-dark-mode',
  ],
  docs: {
    autodocs: true,
  },
  staticDirs: [
    {
      from: path.resolve(__dirname, '../../app/assets/images'),
      to: '/assets/images',
    },
  ],
};
