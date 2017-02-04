/* eslint-disable no-new */
/* global Build */

require('~/lib/utils/datetime_utility');
require('~/lib/utils/url_utility');
require('~/build');
require('~/breakpoints');
require('vendor/jquery.nicescroll');

describe('Build', () => {
  const BUILD_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/builds/1`;
  // see spec/factories/ci/builds.rb
  const BUILD_TRACE = 'BUILD TRACE';
  // see lib/ci/ansi2html.rb
  const INITIAL_BUILD_TRACE_STATE = window.btoa(JSON.stringify({
    offset: BUILD_TRACE.length, n_open_tags: 0, fg_color: null, bg_color: null, style_mask: 0,
  }));

  preloadFixtures('builds/build-with-artifacts.html.raw');

  beforeEach(() => {
    loadFixtures('builds/build-with-artifacts.html.raw');
    spyOn($, 'ajax');
  });

  describe('constructor', () => {
    beforeEach(() => {
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    describe('setup', () => {
      beforeEach(function () {
        this.build = new Build();
      });

      it('copies build options', function () {
        expect(this.build.pageUrl).toBe(BUILD_URL);
        expect(this.build.buildUrl).toBe(`${BUILD_URL}.json`);
        expect(this.build.buildStatus).toBe('success');
        expect(this.build.buildStage).toBe('test');
        expect(this.build.state).toBe(INITIAL_BUILD_TRACE_STATE);
      });

      it('only shows the jobs matching the current stage', () => {
        expect($('.build-job[data-stage="build"]').is(':visible')).toBe(false);
        expect($('.build-job[data-stage="test"]').is(':visible')).toBe(true);
        expect($('.build-job[data-stage="deploy"]').is(':visible')).toBe(false);
      });

      it('selects the current stage in the build dropdown menu', () => {
        expect($('.stage-selection').text()).toBe('test');
      });

      it('updates the jobs when the build dropdown changes', () => {
        $('.stage-item:contains("build")').click();

        expect($('.stage-selection').text()).toBe('build');
        expect($('.build-job[data-stage="build"]').is(':visible')).toBe(true);
        expect($('.build-job[data-stage="test"]').is(':visible')).toBe(false);
        expect($('.build-job[data-stage="deploy"]').is(':visible')).toBe(false);
      });

      it('displays the remove date correctly', () => {
        const removeDateElement = document.querySelector('.js-artifacts-remove');
        expect(removeDateElement.innerText.trim()).toBe('1 year');
      });
    });

    describe('initial build trace', () => {
      beforeEach(() => {
        new Build();
      });

      it('displays the initial build trace', () => {
        expect($.ajax.calls.count()).toBe(1);
        const [{ url, dataType, success, context }] = $.ajax.calls.argsFor(0);
        expect(url).toBe(`${BUILD_URL}.json`);
        expect(dataType).toBe('json');
        expect(success).toEqual(jasmine.any(Function));

        success.call(context, { trace_html: '<span>Example</span>', status: 'running' });

        expect($('#build-trace .js-build-output').text()).toMatch(/Example/);
      });

      it('removes the spinner', () => {
        const [{ success, context }] = $.ajax.calls.argsFor(0);
        success.call(context, { trace_html: '<span>Example</span>', status: 'success' });

        expect($('.js-build-refresh').length).toBe(0);
      });
    });

    describe('running build', () => {
      beforeEach(function () {
        $('.js-build-options').data('buildStatus', 'running');
        this.build = new Build();
        spyOn(this.build, 'location').and.returnValue(BUILD_URL);
      });

      it('updates the build trace on an interval', function () {
        jasmine.clock().tick(4001);

        expect($.ajax.calls.count()).toBe(2);
        let [{ url, dataType, success, context }] = $.ajax.calls.argsFor(1);
        expect(url).toBe(
          `${BUILD_URL}/trace.json?state=${encodeURIComponent(INITIAL_BUILD_TRACE_STATE)}`,
        );
        expect(dataType).toBe('json');
        expect(success).toEqual(jasmine.any(Function));

        success.call(context, {
          html: '<span>Update<span>',
          status: 'running',
          state: 'newstate',
          append: true,
        });

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);
        expect(this.build.state).toBe('newstate');

        jasmine.clock().tick(4001);

        expect($.ajax.calls.count()).toBe(3);
        [{ url, dataType, success, context }] = $.ajax.calls.argsFor(2);
        expect(url).toBe(`${BUILD_URL}/trace.json?state=newstate`);
        expect(dataType).toBe('json');
        expect(success).toEqual(jasmine.any(Function));

        success.call(context, {
          html: '<span>More</span>',
          status: 'running',
          state: 'finalstate',
          append: true,
        });

        expect($('#build-trace .js-build-output').text()).toMatch(/UpdateMore/);
        expect(this.build.state).toBe('finalstate');
      });

      it('replaces the entire build trace', () => {
        jasmine.clock().tick(4001);
        let [{ success, context }] = $.ajax.calls.argsFor(1);
        success.call(context, {
          html: '<span>Update</span>',
          status: 'running',
          append: true,
        });

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);

        jasmine.clock().tick(4001);
        [{ success, context }] = $.ajax.calls.argsFor(2);
        success.call(context, {
          html: '<span>Different</span>',
          status: 'running',
          append: false,
        });

        expect($('#build-trace .js-build-output').text()).not.toMatch(/Update/);
        expect($('#build-trace .js-build-output').text()).toMatch(/Different/);
      });

      it('reloads the page when the build is done', () => {
        spyOn(gl.utils, 'visitUrl');

        jasmine.clock().tick(4001);
        const [{ success, context }] = $.ajax.calls.argsFor(1);
        success.call(context, {
          html: '<span>Final</span>',
          status: 'passed',
          append: true,
        });

        expect(gl.utils.visitUrl).toHaveBeenCalledWith(BUILD_URL);
      });
    });
  });
});
