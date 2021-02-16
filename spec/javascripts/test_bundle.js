/* eslint-disable
  jasmine/no-global-setup, no-underscore-dangle, no-console
*/

import { config as testUtilsConfig } from '@vue/test-utils';
import jasmineDiff from 'jasmine-diff';
import $ from 'jquery';
import 'core-js/features/set-immediate';
import 'vendor/jasmine-jquery';
import '~/commons';
import Vue from 'vue';
import { getDefaultAdapter } from '~/lib/utils/axios_utils';
import Translate from '~/vue_shared/translate';

import { FIXTURES_PATH, TEST_HOST } from './test_constants';

// Tech debt issue TBD
testUtilsConfig.logModifiedComponents = false;

const isHeadlessChrome = /\bHeadlessChrome\//.test(navigator.userAgent);
Vue.config.devtools = !isHeadlessChrome;
Vue.config.productionTip = false;

let hasVueWarnings = false;
Vue.config.warnHandler = (msg, vm, trace) => {
  // The following workaround is necessary, so we are able to use setProps from Vue test utils
  // see https://github.com/vuejs/vue-test-utils/issues/631#issuecomment-421108344
  const currentStack = new Error().stack;
  const isInVueTestUtils = currentStack
    .split('\n')
    .some((line) => line.startsWith('    at VueWrapper.setProps ('));
  if (isInVueTestUtils) {
    return;
  }

  hasVueWarnings = true;
  fail(`${msg}${trace}`);
};

let hasVueErrors = false;
Vue.config.errorHandler = function (err) {
  hasVueErrors = true;
  fail(err);
};

Vue.use(Translate);

// enable test fixtures
jasmine.getFixtures().fixturesPath = FIXTURES_PATH;
jasmine.getJSONFixtures().fixturesPath = FIXTURES_PATH;

beforeAll(() => {
  jasmine.addMatchers(
    jasmineDiff(jasmine, {
      colors: window.__karma__.config.color,
      inline: window.__karma__.config.color,
    }),
  );
});

// globalize common libraries
window.$ = $;
window.jQuery = window.$;

// stub expected globals
window.gl = window.gl || {};
window.gl.TEST_HOST = TEST_HOST;
window.gon = window.gon || {};
window.gon.test_env = true;
window.gon.ee = process.env.IS_EE;
gon.relative_url_root = '';

let hasUnhandledPromiseRejections = false;

window.addEventListener('unhandledrejection', (event) => {
  hasUnhandledPromiseRejections = true;
  console.error('Unhandled promise rejection:');
  console.error(event.reason.stack || event.reason);
});

let longRunningTestTimeoutHandle;

beforeEach((done) => {
  longRunningTestTimeoutHandle = setTimeout(() => {
    done.fail('Test is running too long!');
  }, 4000);
  done();
});

afterEach(() => {
  clearTimeout(longRunningTestTimeoutHandle);
});

const axiosDefaultAdapter = getDefaultAdapter();

// render all of our tests
const testContexts = [require.context('spec', true, /_spec$/)];

if (process.env.IS_EE) {
  testContexts.push(require.context('ee_spec', true, /_spec$/));
}

testContexts.forEach((context) => {
  context.keys().forEach((path) => {
    try {
      context(path);
    } catch (err) {
      console.log(err);
      console.error('[GL SPEC RUNNER ERROR] Unable to load spec: ', path);
      describe('Test bundle', function () {
        it(`includes '${path}'`, function () {
          expect(err).toBeNull();
        });
      });
    }
  });
});

describe('test errors', () => {
  beforeAll((done) => {
    if (hasUnhandledPromiseRejections || hasVueWarnings || hasVueErrors) {
      setTimeout(done, 1000);
    } else {
      done();
    }
  });

  it('has no unhandled Promise rejections', () => {
    expect(hasUnhandledPromiseRejections).toBe(false);
  });

  it('has no Vue warnings', () => {
    expect(hasVueWarnings).toBe(false);
  });

  it('has no Vue error', () => {
    expect(hasVueErrors).toBe(false);
  });

  it('restores axios adapter after mocking', () => {
    if (getDefaultAdapter() !== axiosDefaultAdapter) {
      fail('axios adapter is not restored! Did you forget a restore() on MockAdapter?');
    }
  });
});
