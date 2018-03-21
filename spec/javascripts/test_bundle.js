/* eslint-disable jasmine/no-global-setup */
import $ from 'jquery';
import 'vendor/jasmine-jquery';
import '~/commons';

import Vue from 'vue';
import VueResource from 'vue-resource';

import { getDefaultAdapter } from '~/lib/utils/axios_utils';

const isHeadlessChrome = /\bHeadlessChrome\//.test(navigator.userAgent);
Vue.config.devtools = !isHeadlessChrome;
Vue.config.productionTip = false;

let hasVueWarnings = false;
Vue.config.warnHandler = (msg, vm, trace) => {
  hasVueWarnings = true;
  fail(`${msg}${trace}`);
};

let hasVueErrors = false;
Vue.config.errorHandler = function (err) {
  hasVueErrors = true;
  fail(err);
};

Vue.use(VueResource);

// enable test fixtures
jasmine.getFixtures().fixturesPath = '/base/spec/javascripts/fixtures';
jasmine.getJSONFixtures().fixturesPath = '/base/spec/javascripts/fixtures';

// globalize common libraries
window.$ = window.jQuery = $;

// stub expected globals
window.gl = window.gl || {};
window.gl.TEST_HOST = 'http://test.host';
window.gon = window.gon || {};
window.gon.test_env = true;

let hasUnhandledPromiseRejections = false;

window.addEventListener('unhandledrejection', (event) => {
  hasUnhandledPromiseRejections = true;
  console.error('Unhandled promise rejection:');
  console.error(event.reason.stack || event.reason);
});

// HACK: Chrome 59 disconnects if there are too many synchronous tests in a row
// because it appears to lock up the thread that communicates to Karma's socket
// This async beforeEach gets called on every spec and releases the JS thread long
// enough for the socket to continue to communicate.
// The downside is that it creates a minor performance penalty in the time it takes
// to run our unit tests.
beforeEach(done => done());

const builtinVueHttpInterceptors = Vue.http.interceptors.slice();

beforeEach(() => {
  // restore interceptors so we have no remaining ones from previous tests
  Vue.http.interceptors = builtinVueHttpInterceptors.slice();
});

const axiosDefaultAdapter = getDefaultAdapter();

// render all of our tests
const testsContext = require.context('.', true, /_spec$/);
testsContext.keys().forEach(function (path) {
  try {
    testsContext(path);
  } catch (err) {
    console.error('[ERROR] Unable to load spec: ', path);
    describe('Test bundle', function () {
      it(`includes '${path}'`, function () {
        expect(err).toBeNull();
      });
    });
  }
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

// if we're generating coverage reports, make sure to include all files so
// that we can catch files with 0% coverage
// see: https://github.com/deepsweet/istanbul-instrumenter-loader/issues/15
if (process.env.BABEL_ENV === 'coverage') {
  // exempt these files from the coverage report
  const troubleMakers = [
    './blob_edit/blob_bundle.js',
    './boards/components/modal/empty_state.js',
    './boards/components/modal/footer.js',
    './boards/components/modal/header.js',
    './cycle_analytics/cycle_analytics_bundle.js',
    './cycle_analytics/components/stage_plan_component.js',
    './cycle_analytics/components/stage_staging_component.js',
    './cycle_analytics/components/stage_test_component.js',
    './commit/pipelines/pipelines_bundle.js',
    './diff_notes/diff_notes_bundle.js',
    './diff_notes/components/jump_to_discussion.js',
    './diff_notes/components/resolve_count.js',
    './dispatcher.js',
    './environments/environments_bundle.js',
    './graphs/graphs_bundle.js',
    './issuable/time_tracking/time_tracking_bundle.js',
    './main.js',
    './merge_conflicts/merge_conflicts_bundle.js',
    './merge_conflicts/components/inline_conflict_lines.js',
    './merge_conflicts/components/parallel_conflict_lines.js',
    './monitoring/monitoring_bundle.js',
    './network/network_bundle.js',
    './network/branch_graph.js',
    './profile/profile_bundle.js',
    './protected_branches/protected_branches_bundle.js',
    './snippet/snippet_bundle.js',
    './terminal/terminal_bundle.js',
    './users/users_bundle.js',
    './issue_show/index.js',
  ];

  describe('Uncovered files', function () {
    const sourceFiles = require.context('~', true, /\.js$/);

    $.holdReady(true);

    sourceFiles.keys().forEach(function (path) {
      // ignore if there is a matching spec file
      if (testsContext.keys().indexOf(`${path.replace(/\.js$/, '')}_spec`) > -1) {
        return;
      }

      it(`includes '${path}'`, function () {
        try {
          sourceFiles(path);
        } catch (err) {
          if (troubleMakers.indexOf(path) === -1) {
            expect(err).toBeNull();
          }
        }
      });
    });
  });
}
