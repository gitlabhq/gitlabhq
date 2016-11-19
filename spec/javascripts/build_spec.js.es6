/* eslint-disable no-new */
/* global Build */
/* global Turbolinks */

//= require lib/utils/timeago
//= require lib/utils/datetime_utility
//= require build
//= require breakpoints
//= require jquery.nicescroll
//= require turbolinks

describe('Build', () => {
  // see spec/factories/ci/builds.rb
  const BUILD_TRACE = 'BUILD TRACE';
  // see lib/ci/ansi2html.rb
  const INITIAL_BUILD_TRACE_STATE = window.btoa(JSON.stringify({
    offset: BUILD_TRACE.length, n_open_tags: 0, fg_color: null, bg_color: null, style_mask: 0,
  }));

  fixture.preload('builds/build-with-artifacts.html.raw');

  beforeEach(function () {
    fixture.load('builds/build-with-artifacts.html.raw');
    spyOn($, 'ajax');
  });

  describe('constructor', () => {
    beforeEach(function () {
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    describe('setup', function () {
      beforeEach(function () {
        this.build = new Build();
      });

      it('copies build options', function () {
        expect(this.build.pageUrl).toBe('http://test.host/namespace1/project1/builds/1');
        expect(this.build.buildUrl).toBe('http://test.host/namespace1/project1/builds/1.json');
        expect(this.build.buildStatus).toBe('success');
        expect(this.build.buildStage).toBe('test');
        expect(this.build.state).toBe(INITIAL_BUILD_TRACE_STATE);
      });

      it('only shows the jobs matching the current stage', function () {
        expect($('.build-job[data-stage="build"]').is(':visible')).toBe(false);
        expect($('.build-job[data-stage="test"]').is(':visible')).toBe(true);
        expect($('.build-job[data-stage="deploy"]').is(':visible')).toBe(false);
      });

      it('selects the current stage in the build dropdown menu', function () {
        expect($('.stage-selection').text()).toBe('test');
      });

      it('updates the jobs when the build dropdown changes', function () {
        $('.stage-item:contains("build")').click();

        expect($('.stage-selection').text()).toBe('build');
        expect($('.build-job[data-stage="build"]').is(':visible')).toBe(true);
        expect($('.build-job[data-stage="test"]').is(':visible')).toBe(false);
        expect($('.build-job[data-stage="deploy"]').is(':visible')).toBe(false);
      });

      it('displays the remove date correctly', function () {
        const removeDateElement = document.querySelector('.js-artifacts-remove');
        expect(removeDateElement.innerText.trim()).toBe('1 year');
      });
    });

    describe('initial build trace', function () {
      beforeEach(function () {
        new Build();
      });

      it('displays the initial build trace', function () {
        expect($.ajax.calls.count()).toBe(1);
        const [{ url, dataType, success, context }] = $.ajax.calls.argsFor(0);
        expect(url).toBe('http://test.host/namespace1/project1/builds/1.json');
        expect(dataType).toBe('json');
        expect(success).toEqual(jasmine.any(Function));

        success.call(context, { trace_html: '<span>Example</span>', status: 'running' });

        expect($('#build-trace .js-build-output').text()).toMatch(/Example/);
      });

      it('removes the spinner', function () {
        const [{ success, context }] = $.ajax.calls.argsFor(0);
        success.call(context, { trace_html: '<span>Example</span>', status: 'success' });

        expect($('.js-build-refresh').length).toBe(0);
      });
    });

    describe('running build', function () {
      beforeEach(function () {
        $('.js-build-options').data('buildStatus', 'running');
        this.build = new Build();
        spyOn(this.build, 'location')
          .and.returnValue('http://test.host/namespace1/project1/builds/1');
      });

      it('updates the build trace on an interval', function () {
        jasmine.clock().tick(4001);

        expect($.ajax.calls.count()).toBe(2);
        let [{ url, dataType, success, context }] = $.ajax.calls.argsFor(1);
        expect(url).toBe(
          `http://test.host/namespace1/project1/builds/1/trace.json?state=${encodeURIComponent(INITIAL_BUILD_TRACE_STATE)}`
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
        expect(url).toBe(
          'http://test.host/namespace1/project1/builds/1/trace.json?state=newstate'
        );
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

      it('replaces the entire build trace', function () {
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

      it('reloads the page when the build is done', function () {
        spyOn(Turbolinks, 'visit');

        jasmine.clock().tick(4001);
        const [{ success, context }] = $.ajax.calls.argsFor(1);
        success.call(context, {
          html: '<span>Final</span>',
          status: 'passed',
          append: true,
        });

        expect(Turbolinks.visit).toHaveBeenCalledWith(
          'http://test.host/namespace1/project1/builds/1'
        );
      });
    });
  });
});
