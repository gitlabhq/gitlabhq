/* eslint-disable no-new */
/* global Build */
import { bytesToKiB } from '~/lib/utils/number_utils';
import '~/lib/utils/datetime_utility';
import '~/lib/utils/url_utility';
import '~/build';
import '~/breakpoints';
import 'vendor/jquery.nicescroll';

describe('Build', () => {
  const BUILD_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/jobs/1`;

  preloadFixtures('builds/build-with-artifacts.html.raw');

  beforeEach(() => {
    loadFixtures('builds/build-with-artifacts.html.raw');
    spyOn($, 'ajax');
  });

  describe('class constructor', () => {
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
        expect(this.build.state).toBe('');
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

    describe('running build', () => {
      beforeEach(function () {
        this.build = new Build();
      });

      it('updates the build trace on an interval', function () {
        spyOn(gl.utils, 'visitUrl');

        jasmine.clock().tick(4001);

        expect($.ajax.calls.count()).toBe(1);

        // We have to do it this way to prevent Webpack to fail to compile
        // when destructuring assignments and reusing
        // the same variables names inside the same scope
        let args = $.ajax.calls.argsFor(0)[0];

        expect(args.url).toBe(`${BUILD_URL}/trace.json`);
        expect(args.dataType).toBe('json');
        expect(args.success).toEqual(jasmine.any(Function));

        args.success.call($, {
          html: '<span>Update<span>',
          status: 'running',
          state: 'newstate',
          append: true,
          complete: false,
        });

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);
        expect(this.build.state).toBe('newstate');

        jasmine.clock().tick(4001);

        expect($.ajax.calls.count()).toBe(3);

        args = $.ajax.calls.argsFor(2)[0];
        expect(args.url).toBe(`${BUILD_URL}/trace.json`);
        expect(args.dataType).toBe('json');
        expect(args.data.state).toBe('newstate');
        expect(args.success).toEqual(jasmine.any(Function));

        args.success.call($, {
          html: '<span>More</span>',
          status: 'running',
          state: 'finalstate',
          append: true,
          complete: true,
        });

        expect($('#build-trace .js-build-output').text()).toMatch(/UpdateMore/);
        expect(this.build.state).toBe('finalstate');
      });

      it('replaces the entire build trace', () => {
        spyOn(gl.utils, 'visitUrl');

        jasmine.clock().tick(4001);
        let args = $.ajax.calls.argsFor(0)[0];
        args.success.call($, {
          html: '<span>Update</span>',
          status: 'running',
          append: false,
          complete: false,
        });

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);

        jasmine.clock().tick(4001);
        args = $.ajax.calls.argsFor(2)[0];
        args.success.call($, {
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
        const [{ success }] = $.ajax.calls.argsFor(0);
        success.call($, {
          html: '<span>Final</span>',
          status: 'passed',
          append: true,
          complete: true,
        });

        expect(gl.utils.visitUrl).toHaveBeenCalledWith(BUILD_URL);
      });

      describe('truncated information', () => {
        describe('when size is less than total', () => {
          it('shows information about truncated log', () => {
            jasmine.clock().tick(4001);
            const [{ success }] = $.ajax.calls.argsFor(0);

            success.call($, {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size: 50,
              total: 100,
            });

            expect(document.querySelector('.js-truncated-info').classList).not.toContain('hidden');
          });

          it('shows the size in KiB', () => {
            jasmine.clock().tick(4001);
            const [{ success }] = $.ajax.calls.argsFor(0);
            const size = 50;

            success.call($, {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size,
              total: 100,
            });

            expect(
              document.querySelector('.js-truncated-info-size').textContent.trim(),
            ).toEqual(`${bytesToKiB(size)}`);
          });

          it('shows incremented size', () => {
            jasmine.clock().tick(4001);
            let args = $.ajax.calls.argsFor(0)[0];
            args.success.call($, {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size: 50,
              total: 100,
            });

            expect(
              document.querySelector('.js-truncated-info-size').textContent.trim(),
            ).toEqual(`${bytesToKiB(50)}`);

            jasmine.clock().tick(4001);
            args = $.ajax.calls.argsFor(2)[0];
            args.success.call($, {
              html: '<span>Update</span>',
              status: 'success',
              append: true,
              size: 10,
              total: 100,
            });

            expect(
              document.querySelector('.js-truncated-info-size').textContent.trim(),
            ).toEqual(`${bytesToKiB(60)}`);
          });

          it('renders the raw link', () => {
            jasmine.clock().tick(4001);
            const [{ success }] = $.ajax.calls.argsFor(0);

            success.call($, {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size: 50,
              total: 100,
            });

            expect(
              document.querySelector('.js-raw-link').textContent.trim(),
            ).toContain('Complete Raw');
          });
        });

        describe('when size is equal than total', () => {
          it('does not show the trunctated information', () => {
            jasmine.clock().tick(4001);
            const [{ success }] = $.ajax.calls.argsFor(0);

            success.call($, {
              html: '<span>Update</span>',
              status: 'success',
              append: false,
              size: 100,
              total: 100,
            });

            expect(document.querySelector('.js-truncated-info').classList).toContain('hidden');
          });
        });
      });
    });
  });
});
