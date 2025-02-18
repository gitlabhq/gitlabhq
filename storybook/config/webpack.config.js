/* eslint-disable no-param-reassign */

const { statSync, existsSync } = require('fs');
const path = require('path');
const glob = require('glob');
const sass = require('sass');
const webpack = require('webpack');
const { red } = require('chalk');
const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');
const IS_EE = require('../../config/helpers/is_ee_env');
const IS_JH = require('../../config/helpers/is_jh_env');
const gitlabWebpackConfig = require('../../config/webpack.config');

const ROOT_PATH = path.resolve(__dirname, '..', '..');
const EMPTY_VUE_COMPONENT_PATH = path.join(
  ROOT_PATH,
  'app/assets/javascripts/vue_shared/components/empty_component.js',
);

const buildIncludePaths = (nodeSassIncludePaths, previouslyResolvedPath) => {
  const includePaths = [];
  if (path.isAbsolute(previouslyResolvedPath)) {
    includePaths.push(path.dirname(previouslyResolvedPath));
  }
  return [...new Set([...includePaths, ...nodeSassIncludePaths.split(path.delimiter)])];
};

const resolveGlobUrl = (url, includePaths = []) => {
  const filePaths = new Set();
  if (glob.hasMagic(url)) {
    includePaths.forEach((includePath) => {
      const globPaths = glob.sync(url, { cwd: includePath });
      globPaths.forEach((relativePath) => {
        filePaths.add(
          path
            .resolve(includePath, relativePath)
            // This fixes a problem with importing absolute paths on windows.
            .split(`\\`)
            .join(`/`),
        );
      });
    });
    return [...filePaths];
  }
  return null;
};

const ROOT = path.resolve(__dirname, '../../');
const TRANSPARENT_1X1_PNG =
  'url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==)';
const SASS_INCLUDE_PATHS = [
  'app/assets/stylesheets',
  'app/assets/stylesheets/_ee',
  'app/assets/stylesheets/_jh',
  'ee/app/assets/stylesheets',
  'ee/app/assets/stylesheets/_ee',
  'node_modules/@gitlab/ui/src/vendor',
  'node_modules',
].map((p) => path.resolve(ROOT, p));

if (IS_JH) {
  SASS_INCLUDE_PATHS.push(
    ...['jh/app/assets/stylesheets', 'jh/app/assets/stylesheets/_jh'].map((p) =>
      path.resolve(ROOT, p),
    ),
  );
}

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

/**
 * Custom function to check if file exists in assets path.
 * @param {sass.types.String} url - The value of the Sass variable.
 * @returns {sass.types.String} - The path to the asset.
 */
function checkAssetUrl(url) {
  const urlString = url.getValue();
  const filePath = path.resolve(__dirname, '../../app/assets/images', urlString);

  // Return as is if it's a data URL.
  if (urlString.startsWith('data:')) {
    return new sass.types.String(`url('${urlString}')`);
  }

  // If the file exists, return the absolute file path.
  if (existsSync(filePath)) {
    return new sass.types.String(`url('/assets/images/${urlString}')`);
  }

  // Otherwise, return the placeholder.
  return new sass.types.String(TRANSPARENT_1X1_PNG);
}

const sassLoaderOptions = {
  sassOptions: {
    functions: {
      'image-url($url)': checkAssetUrl,
      'asset_path($url)': checkAssetUrl,
      'asset_url($url)': checkAssetUrl,
      'url($url)': checkAssetUrl,
    },
    includePaths: SASS_INCLUDE_PATHS,
    importer: sassSmartImporter,
  },
};

// Some dependencies need to be transpiled for webpack to be happy
const transpileDependencyConfig = {
  loader: 'babel-loader',
  options: {
    presets: [['@babel/preset-env', { targets: { esmodules: true } }]],
    plugins: [
      // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
      '@babel/plugin-proposal-optional-chaining',
      // See: https://gitlab.com/gitlab-org/gitlab/-/issues/336216
      '@babel/plugin-proposal-nullish-coalescing-operator',
    ],
  },
};

module.exports = function storybookWebpackConfig({ config }) {
  // Add any missing extensions from the main GitLab webpack config
  config.resolve.extensions = Array.from(
    new Set([...config.resolve.extensions, ...gitlabWebpackConfig.resolve.extensions]),
  );
  config.resolve.alias = {
    ...config.resolve.alias,
    gridstack: require.resolve('gridstack/dist/es5/gridstack.js'),
    '@cubejs-client/core': require.resolve('@cubejs-client/core/dist/cubejs-client-core.js'),
  };

  // Replace any Storybook-defined CSS loaders with our custom one.
  config.module.rules = [
    ...config.module.rules.filter((r) => !r.test.test('.css')),
    {
      test: /\.s?css$/,
      exclude: /typescale\/\w+_demo\.scss$/, // skip typescale demo stylesheets
      loaders: [
        'style-loader',
        'css-loader',
        'postcss-loader',
        {
          loader: 'sass-loader',
          options: sassLoaderOptions,
        },
      ],
    },
    {
      test: /\.(graphql|gql)$/,
      exclude: /node_modules/,
      loader: 'graphql-tag/loader',
    },
    {
      test: /\.(zip)$/,
      loader: 'file-loader',
      options: {
        esModule: false,
      },
    },
    {
      test: /marked\/.*\.js?$/,
      use: transpileDependencyConfig,
    },
    {
      test: /\.mjs$/,
      include: /node_modules/,
      type: 'javascript/auto',
    },
    {
      test: /\.(js|cjs)$/,
      include: (modulePath) =>
        /node_modules\/(jsonc-parser|monaco-editor|monaco-worker-manager|monaco-marker-data-provider)/.test(
          modulePath,
        ) || /node_modules\/yaml/.test(modulePath),
      use: transpileDependencyConfig,
    },
  ];

  // Silence webpack warnings about moment/pikaday not being able to resolve.
  config.plugins.push(new webpack.IgnorePlugin(/moment/, /pikaday/));

  config.plugins.push(
    new MonacoWebpackPlugin({
      filename: '[name].[contenthash:8].worker.js',
      customLanguages: [
        {
          label: 'yaml',
          entry: 'monaco-yaml',
          worker: {
            id: 'monaco-yaml/yamlWorker',
            entry: 'monaco-yaml/yaml.worker',
          },
        },
      ],
    }),
  );

  if (!IS_EE) {
    config.plugins.push(
      new webpack.NormalModuleReplacementPlugin(/^ee_component\/(.*)\.vue/, (resource) => {
        resource.request = EMPTY_VUE_COMPONENT_PATH;
      }),
    );
  }

  if (!IS_JH) {
    config.plugins.push(
      new webpack.NormalModuleReplacementPlugin(/^jh_component\/(.*)\.vue/, (resource) => {
        resource.request = EMPTY_VUE_COMPONENT_PATH;
      }),
    );
  }

  if (!IS_EE && !IS_JH) {
    config.plugins.push(
      new webpack.NormalModuleReplacementPlugin(/^jh_else_ee\/(.*)\.vue/, (resource) => {
        resource.request = EMPTY_VUE_COMPONENT_PATH;
      }),
    );
  }

  const baseIntegrationTestHelpersPath = 'spec/frontend_integration/test_helpers';

  // Add any missing aliases from the main GitLab webpack config
  Object.assign(config.resolve.alias, gitlabWebpackConfig.resolve.alias, {
    test_helpers: path.resolve(ROOT, baseIntegrationTestHelpersPath),
    ee_else_ce_test_helpers: path.resolve(ROOT, IS_EE ? 'ee' : '', baseIntegrationTestHelpersPath),
    test_fixtures: path.resolve(ROOT, 'tmp/tests/frontend', IS_EE ? 'fixtures-ee' : 'fixtures'),
  });
  // The main GitLab project aliases this `icons.svg` file to app/assets/javascripts/lib/utils/icons_path.js,
  // which depends on the existence of a global `gon` variable.
  // By deleting the alias, imports of this path will resolve as expected.
  delete config.resolve.alias['@gitlab/svgs/dist/icons.svg'];

  // Fail soft if a story requires a fixture, and the fixture file is absent.
  // Without this, webpack fails at build phase, with a hard to read error.
  // This rewrite rule pushes the error to be runtime.
  config.plugins.push(
    new webpack.NormalModuleReplacementPlugin(/^test_fixtures/, (resource) => {
      const filename = resource.request.replace(
        /^test_fixtures/,
        config.resolve.alias.test_fixtures,
      );
      if (!existsSync(filename)) {
        console.error(red(`\nFixture '${filename}' wasn't found.\n`));
        resource.request = path.join(ROOT, 'storybook', 'fixture_stub.js');
      }
    }),
  );

  return config;
};
