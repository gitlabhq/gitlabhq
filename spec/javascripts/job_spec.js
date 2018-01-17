import { numberToHumanSize } from '~/lib/utils/number_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import '~/lib/utils/datetime_utility';
import Job from '~/job';
import '~/breakpoints';

describe('Job', () => {
  const JOB_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/-/jobs/1`;

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
        this.job = new Job();
      });

      it('copies build options', function () {
        expect(this.job.pagePath).toBe(JOB_URL);
        expect(this.job.buildStatus).toBe('success');
        expect(this.job.buildStage).toBe('test');
        expect(this.job.state).toBe('');
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
        spyOn(urlUtils, 'visitUrl');

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

        this.job = new Job();

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);
        expect(this.job.state).toBe('newstate');

        jasmine.clock().tick(4001);

        expect($('#build-trace .js-build-output').text()).toMatch(/UpdateMore/);
        expect(this.job.state).toBe('finalstate');
      });

      it('replaces the entire build trace', () => {
        const deferred1 = $.Deferred();
        const deferred2 = $.Deferred();
        const deferred3 = $.Deferred();

        spyOn($, 'ajax').and.returnValues(deferred1.promise(), deferred2.promise(), deferred3.promise());

        spyOn(urlUtils, 'visitUrl');

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

        this.job = new Job();

        expect($('#build-trace .js-build-output').text()).toMatch(/Update/);

        jasmine.clock().tick(4001);

        expect($('#build-trace .js-build-output').text()).not.toMatch(/Update/);
        expect($('#build-trace .js-build-output').text()).toMatch(/Different/);
      });
    });

    describe('truncated information', () => {
      describe('when size is less than total', () => {
        it('shows information about truncated log', () => {
          spyOn(urlUtils, 'visitUrl');
          const deferred = $.Deferred();
          spyOn($, 'ajax').and.returnValue(deferred.promise());

          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          });

          this.job = new Job();

          expect(document.querySelector('.js-truncated-info').classList).not.toContain('hidden');
        });

        it('shows the size in KiB', () => {
          const size = 50;
          spyOn(urlUtils, 'visitUrl');
          const deferred = $.Deferred();

          spyOn($, 'ajax').and.returnValue(deferred.promise());
          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size,
            total: 100,
          });

          this.job = new Job();

          expect(
            document.querySelector('.js-truncated-info-size').textContent.trim(),
          ).toEqual(`${numberToHumanSize(size)}`);
        });

        it('shows incremented size', () => {
          const deferred1 = $.Deferred();
          const deferred2 = $.Deferred();
          const deferred3 = $.Deferred();

          spyOn($, 'ajax').and.returnValues(deferred1.promise(), deferred2.promise(), deferred3.promise());

          spyOn(urlUtils, 'visitUrl');

          deferred1.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          });

          deferred2.resolve();

          this.job = new Job();

          expect(
            document.querySelector('.js-truncated-info-size').textContent.trim(),
          ).toEqual(`${numberToHumanSize(50)}`);

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
          ).toEqual(`${numberToHumanSize(60)}`);
        });

        it('renders the raw link', () => {
          const deferred = $.Deferred();
          spyOn(urlUtils, 'visitUrl');

          spyOn($, 'ajax').and.returnValue(deferred.promise());
          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          });

          this.job = new Job();

          expect(
            document.querySelector('.js-raw-link').textContent.trim(),
          ).toContain('Complete Raw');
        });
      });

      describe('when size is equal than total', () => {
        it('does not show the trunctated information', () => {
          const deferred = $.Deferred();
          spyOn(urlUtils, 'visitUrl');

          spyOn($, 'ajax').and.returnValue(deferred.promise());
          deferred.resolve({
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 100,
            total: 100,
          });

          this.job = new Job();

          expect(document.querySelector('.js-truncated-info').classList).toContain('hidden');
        });
      });
    });

    describe('output trace', () => {
      beforeEach(() => {
        const deferred = $.Deferred();
        spyOn(urlUtils, 'visitUrl');

        spyOn($, 'ajax').and.returnValue(deferred.promise());
        deferred.resolve({
          html: '<span>Update</span>',
          status: 'success',
          append: false,
          size: 50,
          total: 100,
        });

        this.job = new Job();
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

  describe('getBuildTrace', () => {
    it('should request build trace with state parameter', (done) => {
      spyOn(jQuery, 'ajax').and.callThrough();
      // eslint-disable-next-line no-new
      new Job();

      setTimeout(() => {
        expect(jQuery.ajax).toHaveBeenCalledWith(
          { url: `${JOB_URL}/trace.json`, data: { state: '' } },
        );
        done();
      }, 0);
    });
  });
});
