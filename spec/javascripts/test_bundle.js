// enable test fixtures
require('jasmine-jquery');

jasmine.getFixtures().fixturesPath = 'base/spec/javascripts/fixtures';
jasmine.getJSONFixtures().fixturesPath = 'base/spec/javascripts/fixtures';

// include common libraries
window.$ = window.jQuery = require('jquery');
window._ = require('underscore');
window.Cookies = require('js-cookie');
window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('jquery-ujs');
require('bootstrap/js/affix');
require('bootstrap/js/alert');
require('bootstrap/js/button');
require('bootstrap/js/collapse');
require('bootstrap/js/dropdown');
require('bootstrap/js/modal');
require('bootstrap/js/scrollspy');
require('bootstrap/js/tab');
require('bootstrap/js/transition');
require('bootstrap/js/tooltip');
require('bootstrap/js/popover');

// stub expected globals
window.gl = window.gl || {};
window.gl.TEST_HOST = 'http://test.host';
window.gon = window.gon || {};

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

// workaround: include all source files to find files with 0% coverage
// see also https://github.com/deepsweet/istanbul-instrumenter-loader/issues/15
describe('Uncovered files', function () {
  // the following files throw errors because of undefined variables
  const troubleMakers = [
    './blob_edit/blob_edit_bundle.js',
    './cycle_analytics/components/stage_plan_component.js',
    './cycle_analytics/components/stage_staging_component.js',
    './cycle_analytics/components/stage_test_component.js',
    './diff_notes/components/jump_to_discussion.js',
    './diff_notes/components/resolve_count.js',
    './merge_conflicts/components/inline_conflict_lines.js',
    './merge_conflicts/components/parallel_conflict_lines.js',
    './network/branch_graph.js',
  ];

  const sourceFiles = require.context('~', true, /^\.\/(?!application\.js).*\.(js|es6)$/);
  sourceFiles.keys().forEach(function (path) {
    // ignore if there is a matching spec file
    if (testsContext.keys().indexOf(`${path.replace(/\.js(\.es6)?$/, '')}_spec`) > -1) {
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
