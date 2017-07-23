/* eslint-disable no-new */
/* global Build */
import { bytesToKiB } from '~/lib/utils/number_utils';
import '~/lib/utils/datetime_utility';
import '~/lib/utils/url_utility';
import '~/build';
import '~/breakpoints';
import 'vendor/jquery.nicescroll';

describe('Build', () => {
  const BUILD_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/-/jobs/1`;

  preloadFixtures('builds/build-with-artifacts.html.raw');

  beforeEach(() => {
    loadFixtures('builds/build-with-artifacts.html.raw');
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
        expect(removeDateElement.innerText.trim()).toBe('1 year remaining');
      });
    });

    describe('running build', () => {
      it('updates the build trace on an interval', function () {
        const deferred1 = $.Deferred();
        const deferred2 = $.Deferred();
        const deferred3 = $.Deferred();
        spyOn($, 'ajax').and.returnValues(deferred1.promise(), deferred2.promise(), deferred3.promise());
        spyOn(gl.utils, 'visitUrl');

        deferred1.resolve({
          html: '<span>Update<span>',
          status: 'running',
          state: 'newstate',
          append: true,
          complete: false,
        });

        deferred2.resolve();

        deferred3.resolve({
          html: '<span>More</span>',
          status: 'running',
          state: 'finalstate',
          append: true,
          complete: true,
        });

        this.build = new Build();

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);
        expect(this.build.state).toBe('newstate');

        jasmine.clock().tick(4001);

        expect($('#build-trace .js-build-output').text()).toMatch(/UpdateMore/);
        expect(this.build.state).toBe('finalstate');
      });

      it('replaces the entire build trace', () => {
        const deferred1 = $.Deferred();
        const deferred2 = $.Deferred();
        const deferred3 = $.Deferred();

        spyOn($, 'ajax').and.returnValues(deferred1.promise(), deferred2.promise(), deferred3.promise());

        spyOn(gl.utils, 'visitUrl');

        deferred1.resolve({
          html: '<span>Update<span>',
          status: 'running',
          append: false,
          complete: false,
        });

        deferred2.resolve();

        deferred3.resolve({
          html: '<span>Different</span>',
          status: 'running',
          append: false,
        });

        this.build = new Build();

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);

        jasmine.clock().tick(4001);

        expect($('#build-trace .js-build-output').text()).not.toMatch(/Update/);
        expect($('#build-trace .js-build-output').text()).toMatch(/Different/);
      });
    });

    describe('truncated information', () => {
      describe('when size is less than total', () => {
        it('shows information about truncated log', () => {
          spyOn(gl.utils, 'visitUrl');
          const deferred = $.Deferred();
          spyOn($, 'ajax').and.returnValue(deferred.promise());

          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          });

          this.build = new Build();

          expect(document.querySelector('.js-truncated-info').classList).not.toContain('hidden');
        });

        it('shows the size in KiB', () => {
          const size = 50;
          spyOn(gl.utils, 'visitUrl');
          const deferred = $.Deferred();

          spyOn($, 'ajax').and.returnValue(deferred.promise());
          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size,
            total: 100,
          });

          this.build = new Build();

          expect(
            document.querySelector('.js-truncated-info-size').textContent.trim(),
          ).toEqual(`${bytesToKiB(size)}`);
        });

        it('shows incremented size', () => {
          const deferred1 = $.Deferred();
          const deferred2 = $.Deferred();
          const deferred3 = $.Deferred();

          spyOn($, 'ajax').and.returnValues(deferred1.promise(), deferred2.promise(), deferred3.promise());

          spyOn(gl.utils, 'visitUrl');

          deferred1.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          });

          deferred2.resolve();

          this.build = new Build();

          expect(
            document.querySelector('.js-truncated-info-size').textContent.trim(),
          ).toEqual(`${bytesToKiB(50)}`);

          jasmine.clock().tick(4001);

          deferred3.resolve({
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
          const deferred = $.Deferred();
          spyOn(gl.utils, 'visitUrl');

          spyOn($, 'ajax').and.returnValue(deferred.promise());
          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          });

          this.build = new Build();

          expect(
            document.querySelector('.js-raw-link').textContent.trim(),
          ).toContain('Complete Raw');
        });
      });

      describe('when size is equal than total', () => {
        it('does not show the trunctated information', () => {
          const deferred = $.Deferred();
          spyOn(gl.utils, 'visitUrl');

          spyOn($, 'ajax').and.returnValue(deferred.promise());
          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 100,
            total: 100,
          });

          this.build = new Build();

          expect(document.querySelector('.js-truncated-info').classList).toContain('hidden');
        });
      });
    });

    describe('output trace', () => {
      beforeEach(() => {
        const deferred = $.Deferred();
        spyOn(gl.utils, 'visitUrl');

        spyOn($, 'ajax').and.returnValue(deferred.promise());
        deferred.resolve({
          html: '<span>Update</span>',
          status: 'success',
          append: false,
          size: 50,
          total: 100,
        });

        this.build = new Build();
      });

      it('should render trace controls', () => {
        const controllers = document.querySelector('.controllers');

        expect(controllers.querySelector('.js-raw-link-controller')).toBeDefined();
        expect(controllers.querySelector('.js-erase-link')).toBeDefined();
        expect(controllers.querySelector('.js-scroll-up')).toBeDefined();
        expect(controllers.querySelector('.js-scroll-down')).toBeDefined();
      });

      it('should render received output', () => {
        expect(
          document.querySelector('.js-build-output').innerHTML,
        ).toEqual('<span>Update</span>');
      });
    });
  });
});
