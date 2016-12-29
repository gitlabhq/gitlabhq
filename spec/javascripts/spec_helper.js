require('jasmine-jquery');

jasmine.getFixtures().fixturesPath = 'base/spec/javascripts/fixtures';
jasmine.getJSONFixtures().fixturesPath = 'base/spec/javascripts/fixtures';

window.gl = window.gl || {};
window.gl.TEST_HOST = 'http://test.host';
window.gon = window.gon || {};
