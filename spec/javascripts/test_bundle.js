// enable test fixtures
require('jasmine-jquery');

jasmine.getFixtures().fixturesPath = 'base/spec/javascripts/fixtures';
jasmine.getJSONFixtures().fixturesPath = 'base/spec/javascripts/fixtures';

// include common libraries
require('~/commons/index.js');
window.$ = window.jQuery = require('jquery');
window._ = require('underscore');

window.addEventListener('error', console.error);

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

// if we're generating coverage reports, make sure to include all files so
// that we can catch files with 0% coverage
// see: https://github.com/deepsweet/istanbul-instrumenter-loader/issues/15
if (process.env.BABEL_ENV === 'coverage') {
  // exempt these files from the coverage report
  const troubleMakers = [
    './blob_edit/blob_bundle.js',
    './boards/boards_bundle.js',
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
    './filtered_search/filtered_search_bundle.js',
    './graphs/graphs_bundle.js',
    './issuable/issuable_bundle.js',
    './issuable/time_tracking/time_tracking_bundle.js',
    './main.js',
    './merge_conflicts/merge_conflicts_bundle.js',
    './merge_conflicts/components/inline_conflict_lines.js',
    './merge_conflicts/components/parallel_conflict_lines.js',
    './merge_request_widget/ci_bundle.js',
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
