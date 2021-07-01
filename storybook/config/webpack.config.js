/* eslint-disable no-param-reassign */

const { statSync } = require('fs');
const path = require('path');
const sass = require('node-sass'); // eslint-disable-line import/no-unresolved
const { buildIncludePaths, resolveGlobUrl } = require('node-sass-magic-importer/dist/toolbox'); // eslint-disable-line import/no-unresolved
const webpack = require('webpack');
const gitlabWebpackConfig = require('../../config/webpack.config');

const ROOT = path.resolve(__dirname, '../../');
const TRANSPARENT_1X1_PNG =
  'url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==)';
const SASS_INCLUDE_PATHS = [
  'app/assets/stylesheets',
  'app/assets/stylesheets/_ee',
  'ee/app/assets/stylesheets',
  'ee/app/assets/stylesheets/_ee',
  'node_modules',
].map((p) => path.resolve(ROOT, p));

/**
 * Custom importer for node-sass, used when LibSass encounters the `@import` directive.
 * Doc source: https://github.com/sass/node-sass#importer--v200---experimental
 * @param {*} url the path in import as-is, which LibSass encountered.
 * @param {*} prev the previously resolved path.
 * @returns {Object | null} the new import string.
 */
function sassSmartImporter(url, prev) {
  const nodeSassOptions = this.options;
  const includePaths = buildIncludePaths(nodeSassOptions.includePaths, prev).filter(
    (includePath) => !includePath.includes('node_modules'),
  );

  // GitLab extensively uses glob-style import paths, but
  // Sass doesn't support glob-style URLs out of the box.
  // Here, we try and resolve the glob URL.
  // If it resolves, we update the @import statement with the resolved path.
  const filePaths = resolveGlobUrl(url, includePaths);
  if (filePaths) {
    const contents = filePaths
      .filter((file) => statSync(file).isFile())
      .map((x) => `@import '${x}';`)
      .join(`\n`);

    return { contents };
  }

  return null;
}

const sassLoaderOptions = {
  functions: {
    'image-url($url)': function sassImageUrlStub() {
      return new sass.types.String(TRANSPARENT_1X1_PNG);
    },
    'asset_path($url)': function sassAssetPathStub() {
      return new sass.types.String(TRANSPARENT_1X1_PNG);
    },
    'asset_url($url)': function sassAssetUrlStub() {
      return new sass.types.String(TRANSPARENT_1X1_PNG);
    },
    'url($url)': function sassUrlStub() {
      return new sass.types.String(TRANSPARENT_1X1_PNG);
    },
  },
  includePaths: SASS_INCLUDE_PATHS,
  importer: sassSmartImporter,
};

module.exports = function storybookWebpackConfig({ config }) {
  // Add any missing extensions from the main GitLab webpack config
  config.resolve.extensions = Array.from(
    new Set([...config.resolve.extensions, ...gitlabWebpackConfig.resolve.extensions]),
  );

  // Replace any Storybook-defined CSS loaders with our custom one.
  config.module.rules = [
    ...config.module.rules.filter((r) => !r.test.test('.css')),
    {
      test: /\.s?css$/,
      exclude: /typescale\/\w+_demo\.scss$/, // skip typescale demo stylesheets
      loaders: [
        'style-loader',
        'css-loader',
        {
          loader: 'sass-loader',
          options: sassLoaderOptions,
        },
      ],
    },
  ];

  // Silence webpack warnings about moment/pikaday not being able to resolve.
  config.plugins.push(new webpack.IgnorePlugin(/moment/, /pikaday/));

  // Add any missing aliases from the main GitLab webpack config
  Object.assign(config.resolve.alias, gitlabWebpackConfig.resolve.alias);
  // The main GitLab project aliases this `icons.svg` file to app/assets/javascripts/lib/utils/icons_path.js,
  // which depends on the existence of a global `gon` variable.
  // By deleting the alias, imports of this path will resolve as expected.
  delete config.resolve.alias['@gitlab/svgs/dist/icons.svg'];

  return config;
};
