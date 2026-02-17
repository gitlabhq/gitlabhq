import { readFileSync } from 'node:fs';
import path from 'node:path';

import { defineConfig } from 'vite';
import vue2 from '@vitejs/plugin-vue2';
// eslint-disable-next-line import/no-unresolved -- False positive: eslint doesn't read `exports` and reports `unresolved`. See https://github.com/import-js/eslint-plugin-import/issues/1810
import vue3 from '@vitejs/plugin-vue';
import graphql from '@rollup/plugin-graphql';
import glob from 'glob';
import webpackConfig from './config/webpack.config';
import {
  IS_EE,
  IS_JH,
  SOURCEGRAPH_PUBLIC_PATH,
  GITLAB_WEB_IDE_PUBLIC_PATH,
  copyFilesPatterns,
} from './config/webpack.constants';
import { PDF_JS_WORKER_PUBLIC_PATH, PDF_JS_CMAPS_PUBLIC_PATH } from './config/pdfjs.constants';

import { viteTailwindCompilerPlugin } from './scripts/frontend/tailwindcss.cjs';
import { CopyPlugin } from './config/helpers/vite_plugin_copy.mjs';
import { AutoStopPlugin } from './config/helpers/vite_plugin_auto_stop.mjs';
import { PageEntrypointsPlugin } from './config/helpers/vite_plugin_page_entrypoints.mjs';
import { FixedRubyPlugin } from './config/helpers/vite_plugin_ruby_fixed.mjs';
import { StylePlugin } from './config/helpers/vite_plugin_style.mjs';
import { IconsPlugin } from './config/helpers/vite_plugin_icons.mjs';
import { ImagesPlugin } from './config/helpers/vite_plugin_images.mjs';
import { CrossOriginWorkerPlugin } from './config/helpers/vite_plugin_cross_origin_worker';
import { PrebuildDuoNext } from './config/helpers/vite_plugin_prebuild_duo_next';
import vue3TemplateCompiler from './config/vue3migration/vue3_template_compiler';
import * as vue3SfcCompiler from './config/vue3migration/vue3_sfc_compiler.mjs';

const { VUE_VERSION: EXPLICIT_VUE_VERSION } = process.env;
const { VUE_COMPILER_VERSION = EXPLICIT_VUE_VERSION } = process.env;
if (![undefined, '2', '3'].includes(EXPLICIT_VUE_VERSION)) {
  throw new Error(
    `Invalid VUE_VERSION value: ${EXPLICIT_VUE_VERSION}. Only '2' and '3' are supported`,
  );
}
const USE_VUE3 = EXPLICIT_VUE_VERSION === '3';
const USE_VUE3_COMPILER = VUE_COMPILER_VERSION === '3';

if (USE_VUE3) {
  console.log('[V] Using Vue.js 3');
} else {
  console.log('[V] Using Vue.js 2');
}
const vue = USE_VUE3 ? vue3 : vue2;

let viteGDKConfig;
try {
  viteGDKConfig = JSON.parse(
    readFileSync(path.resolve(__dirname, 'config/vite.gdk.json'), 'utf-8'),
  );
} catch {
  viteGDKConfig = {};
}

const aliasArr = Object.entries(webpackConfig.resolve.alias).map(([find, replacement]) => ({
  find: find.includes('$') ? new RegExp(find) : find,
  replacement,
}));

const assetsPath = path.resolve(__dirname, 'app/assets');
const nodeModulesPath = path.resolve(__dirname, 'node_modules');
const javascriptsPath = path.resolve(assetsPath, 'javascripts');

const emptyComponent = path.resolve(javascriptsPath, 'vue_shared/components/empty_component.js');

const vueRule = webpackConfig.module.rules.find((rule) => rule.test?.toString() === '/\\.vue$/');
if (!vueRule?.options?.compilerOptions) {
  throw new Error(
    'Could not find compilerOptions in webpack config for .vue rule. ' +
      'Please ensure webpack.config.js has a .vue rule with options.compilerOptions defined.',
  );
}

const EE_ALIAS_FALLBACK = [
  {
    find: /^ee_component\/(.*)\.vue/,
    replacement: emptyComponent,
  },
];

const JH_ALIAS_FALLBACK = [
  {
    find: /^jh_component\/(.*)\.vue/,
    replacement: emptyComponent,
  },
];

const JH_ELSE_EE_ALIAS_FALLBACK = [
  {
    find: /^jh_else_ee\/(.*)\.vue/,
    replacement: emptyComponent,
  },
];

export default defineConfig({
  cacheDir: path.resolve(__dirname, 'tmp/cache/vite'),
  resolve: {
    alias: [
      ...aliasArr,
      ...(IS_EE ? [] : EE_ALIAS_FALLBACK),
      ...(IS_JH ? [] : JH_ALIAS_FALLBACK),
      ...(!IS_EE && !IS_JH ? JH_ELSE_EE_ALIAS_FALLBACK : []),
      {
        find: '~katex',
        replacement: 'katex',
      },
      /*
       Alias for GitLab Fonts
       If we were to import directly from node_modules,
       we would get the files under `public/assets/@gitlab`
       with the assets pipeline. That seems less than ideal
       */
      {
        find: /^gitlab-(sans|mono)\//,
        replacement: '@gitlab/fonts/gitlab-$1/',
      },
    ],
  },
  plugins: [
    PageEntrypointsPlugin(),
    IconsPlugin(),
    ImagesPlugin(),
    StylePlugin({ shouldWatch: viteGDKConfig.hmr !== null }),
    viteTailwindCompilerPlugin({ shouldWatch: viteGDKConfig.hmr !== null }),
    viteTailwindCompilerPlugin({ shouldWatch: viteGDKConfig.hmr !== null, buildCQs: true }),
    CopyPlugin({
      patterns: copyFilesPatterns,
    }),
    viteGDKConfig.enabled ? AutoStopPlugin() : null,
    FixedRubyPlugin(),
    vue({
      // For Vue 3: use custom SFC compiler (top-level `compiler` option)
      // For Vue 2: use custom template compiler (`template.compiler` option)
      ...(USE_VUE3 && USE_VUE3_COMPILER ? { compiler: vue3SfcCompiler } : {}),
      template: {
        ...(!USE_VUE3 && USE_VUE3_COMPILER ? { compiler: vue3TemplateCompiler } : {}),
        compilerOptions: vueRule.options.compilerOptions,
      },
    }),
    graphql(),
    CrossOriginWorkerPlugin(),
    PrebuildDuoNext(),
  ],
  define: {
    // window can be undefined in a Web Worker
    IS_EE: IS_EE
      ? JSON.stringify('typeof window !== "undefined" && window.gon && window.gon.ee')
      : JSON.stringify(false),
    IS_JH: IS_JH
      ? JSON.stringify('typeof window !== "undefined" && window.gon && window.gon.jh')
      : JSON.stringify(false),
    'process.platform': JSON.stringify(''),
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    'process.env.SOURCEGRAPH_PUBLIC_PATH': JSON.stringify(SOURCEGRAPH_PUBLIC_PATH),
    'process.env.GITLAB_WEB_IDE_PUBLIC_PATH': JSON.stringify(GITLAB_WEB_IDE_PUBLIC_PATH),
    'window.IS_VITE': JSON.stringify(true),
    'window.VUE_DEVTOOLS_CONFIG.openInEditorHost': JSON.stringify(
      `${viteGDKConfig.https?.enabled ? 'https' : 'http'}://${viteGDKConfig.public_host}:${viteGDKConfig.port}/assets/vite/`,
    ),
    'process.env.PDF_JS_WORKER_PUBLIC_PATH': JSON.stringify(PDF_JS_WORKER_PUBLIC_PATH),
    'process.env.PDF_JS_CMAPS_UBLIC_PATH': JSON.stringify(PDF_JS_CMAPS_PUBLIC_PATH),
  },
  server: {
    // this fixes Vite server being unreachable on some configurations
    host: '0.0.0.0',
    cors: true,
    warmup: {
      clientFiles: ['javascripts/entrypoints/main.js', 'javascripts/entrypoints/super_sidebar.js'],
    },
    https: viteGDKConfig.https?.enabled
      ? {
          key: viteGDKConfig.https?.key,
          cert: viteGDKConfig.https?.certificate,
        }
      : false,
    watch:
      viteGDKConfig.hmr === null
        ? null
        : {
            ignored: [
              '**/*.stories.js',
              '**/css_in_js.js',
              function ignoreRootFolder(x) {
                /*
             `vite` watches the root folder of gitlab and all of its sub folders
             This is not what we want, because we have temp files, and all kind
             of other stuff. As vite starts its watchers recursively, we just
             ignore if the path matches exactly the root folder

             Additional folders like `ee/app/assets` are defined in
             */
                return x === __dirname;
              },
            ],
          },
  },
  worker: {
    format: 'es',
  },
  optimizeDeps: {
    esbuildOptions: {
      define: {
        __VUE_OPTIONS_API__: 'true',
        __VUE_PROD_DEVTOOLS__: 'false',
        __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: 'false',
      },
    },
    exclude: ['@gitlab/ui'],
    include: [
      // When building @gitlab/ui from source, lodash imports fail in vite because lodash publishes commonjs modules.
      // Vite supports glob expansions in `optimizeDeps.include` that solves this, but it adds a `.js` extension in the
      // resulting `includes` entries so lodash imports do not get re-included correctly. Make our own glob expansion
      // that expands to:
      //   [ '@gitlab/ui > lodash/add', '@gitlab/ui > lodash/after', '@gitlab/ui > lodash/array', ... ]
      ...glob
        .sync('lodash/**/[a-zA-Z]*.js', { cwd: nodeModulesPath })
        .map((m) => m.replace('.js', ''))
        .map((m) => `@gitlab/ui > ${m}`),
    ],
  },
  build: {
    // speed up build in CI by disabling sourcemaps and compression
    // TODO: allow sourcemaps and compression when we are ready for Vite in production
    sourcemap: false,
    minify: false,
    cssMinify: false,
    reportCompressedSize: false,
  },
});
