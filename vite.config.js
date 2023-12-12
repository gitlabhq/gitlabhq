import path from 'path';
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue2';
import graphql from '@rollup/plugin-graphql';
import RubyPlugin from 'vite-plugin-ruby';
import chokidar from 'chokidar';
import { viteCommonjs } from '@originjs/vite-plugin-commonjs';
import webpackConfig from './config/webpack.config';
import {
  IS_EE,
  IS_JH,
  SOURCEGRAPH_PUBLIC_PATH,
  GITLAB_WEB_IDE_PUBLIC_PATH,
} from './config/webpack.constants';
import viteSharedConfig from './config/vite.json';

const aliasArr = Object.entries(webpackConfig.resolve.alias).map(([find, replacement]) => ({
  find: find.includes('$') ? new RegExp(find) : find,
  replacement,
}));

const assetsPath = path.resolve(__dirname, 'app/assets');
const javascriptsPath = path.resolve(assetsPath, 'javascripts');

const emptyComponent = path.resolve(javascriptsPath, 'vue_shared/components/empty_component.js');

const [rubyPlugin, ...rest] = RubyPlugin();

// We can't use regular 'resolve' which points to sourceCodeDir in vite.json
// Because we need for '~' alias to resolve to app/assets/javascripts
// We can't use javascripts folder in sourceCodeDir because we also need to resolve other assets
// With undefined 'resolve' an '~' alias from Webpack config is used instead
// See the issue for details: https://github.com/ElMassimo/vite_ruby/issues/237
const fixedRubyPlugin = [
  {
    ...rubyPlugin,
    config: (...args) => {
      const originalConfig = rubyPlugin.config(...args);
      return {
        ...originalConfig,
        resolve: undefined,
      };
    },
  },
  ...rest,
];

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

const autoRestartPlugin = {
  configureServer(server) {
    const watcher = chokidar.watch(['node_modules/.yarn-integrity'], {
      ignoreInitial: true,
    });

    // GDK will restart Vite server for us
    const stop = () => server.stop();

    watcher.on('add', stop);
    watcher.on('change', stop);
    watcher.on('unlink', stop);

    server.httpServer?.addListener?.('close', () => watcher.close());
  },
};

export default defineConfig({
  cacheDir: path.resolve(__dirname, 'tmp/cache/vite'),
  resolve: {
    alias: [
      ...aliasArr,
      ...(IS_EE ? [] : EE_ALIAS_FALLBACK),
      ...(IS_JH ? [] : JH_ALIAS_FALLBACK),
      {
        find: '~/',
        replacement: javascriptsPath,
      },
      {
        find: '~katex',
        replacement: 'katex',
      },
    ],
  },
  plugins: [
    // VITE_ENABLED is present when running with GDK
    process.env.VITE_ENABLED ? autoRestartPlugin : null,
    fixedRubyPlugin,
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
  },
  server: {
    hmr: {
      host: viteSharedConfig?.development?.host || 'localhost',
      // ensure we stay compatible with HTTPS enabled for GDK
      protocol: 'ws',
    },
    https: false,
    watch: {
      ignored: [
        '**/*.stories.js',
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
});
