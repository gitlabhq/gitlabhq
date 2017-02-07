// enable test fixtures
require('jasmine-jquery');

jasmine.getFixtures().fixturesPath = 'base/spec/javascripts/fixtures';
jasmine.getJSONFixtures().fixturesPath = 'base/spec/javascripts/fixtures';

// include common libraries
window.$ = window.jQuery = require('jquery');
window._ = require('underscore');
window.Cookies = require('vendor/js.cookie');
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
