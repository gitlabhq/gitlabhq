import { readFileSync } from 'node:fs';
import path from 'node:path';

import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue2';
import graphql from '@rollup/plugin-graphql';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';
import webpackConfig from './config/webpack.config';
import {
  IS_EE,
  IS_JH,
  SOURCEGRAPH_PUBLIC_PATH,
  GITLAB_WEB_IDE_PUBLIC_PATH,
  copyFilesPatterns,
} from './config/webpack.constants';
import { PDF_JS_WORKER_PUBLIC_PATH, PDF_JS_CMAPS_PUBLIC_PATH } from './config/pdfjs.constants';

import { viteTailwindCompilerPlugin } from './scripts/frontend/tailwindcss.mjs';
import { CopyPlugin } from './config/helpers/vite_plugin_copy.mjs';
import { AutoStopPlugin } from './config/helpers/vite_plugin_auto_stop.mjs';
import { PageEntrypointsPlugin } from './config/helpers/vite_plugin_page_entrypoints.mjs';
import { FixedRubyPlugin } from './config/helpers/vite_plugin_ruby_fixed.mjs';
import { StylePlugin } from './config/helpers/vite_plugin_style.mjs';
import { IconsPlugin } from './config/helpers/vite_plugin_icons.mjs';
import { ImagesPlugin } from './config/helpers/vite_plugin_images.mjs';

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
const javascriptsPath = path.resolve(assetsPath, 'javascripts');

const emptyComponent = path.resolve(javascriptsPath, 'vue_shared/components/empty_component.js');

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
        replacement: 'node_modules/@gitlab/fonts/gitlab-$1/',
      },
    ],
  },
  plugins: [
    PageEntrypointsPlugin(),
    IconsPlugin(),
    ImagesPlugin(),
    StylePlugin({ shouldWatch: viteGDKConfig.hmr !== null }),
    viteTailwindCompilerPlugin({ shouldWatch: viteGDKConfig.hmr !== null }),
    CopyPlugin({
      patterns: copyFilesPatterns,
    }),
    viteGDKConfig.enabled ? AutoStopPlugin() : null,
    FixedRubyPlugin(),
    vue({
      template: {
        compilerOptions: {
          whitespace: 'preserve',
        },
      },
    }),
    graphql(),
    viteCommonjs({
      include: [path.resolve(javascriptsPath, 'locale/ensure_single_line.cjs')],
    }),
  ],
  define: {
    // window can be undefined in a Web Worker
    IS_EE: IS_EE
      ? JSON.stringify('typeof window !== "undefined" && window.gon && window.gon.ee')
      : JSON.stringify(false),
    IS_JH: IS_JH
      ? JSON.stringify('typeof window !== "undefined" && window.gon && window.gon.jh')
      : JSON.stringify(false),
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    'process.env.SOURCEGRAPH_PUBLIC_PATH': JSON.stringify(SOURCEGRAPH_PUBLIC_PATH),
    'process.env.GITLAB_WEB_IDE_PUBLIC_PATH': JSON.stringify(GITLAB_WEB_IDE_PUBLIC_PATH),
    'window.IS_VITE': JSON.stringify(true),
    'window.VUE_DEVTOOLS_CONFIG.openInEditorHost': JSON.stringify(
      viteGDKConfig.hmr
        ? `${process.env.VITE_HMR_HTTP_URL}/vite-dev/`
        : `http://${viteGDKConfig.host}:${viteGDKConfig.port}/vite-dev/`,
    ),
    'process.env.PDF_JS_WORKER_PUBLIC_PATH': JSON.stringify(PDF_JS_WORKER_PUBLIC_PATH),
    'process.env.PDF_JS_CMAPS_UBLIC_PATH': JSON.stringify(PDF_JS_CMAPS_PUBLIC_PATH),
  },
  server: {
    cors: true,
    warmup: {
      clientFiles: ['javascripts/entrypoints/main.js', 'javascripts/entrypoints/super_sidebar.js'],
    },
    hmr: viteGDKConfig.hmr,
    https: false,
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
});
