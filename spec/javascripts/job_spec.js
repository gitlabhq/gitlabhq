import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import '~/lib/utils/datetime_utility';
import Job from '~/job';
import '~/breakpoints';

describe('Job', () => {
  const JOB_URL = `${gl.TEST_HOST}/frontend-fixtures/builds-project/-/jobs/1`;
  let mock;
  let response;
  let job;

  function waitForPromise() {
    return new Promise(resolve => requestAnimationFrame(resolve));
  }

  preloadFixtures('builds/build-with-artifacts.html.raw');

  beforeEach(() => {
    loadFixtures('builds/build-with-artifacts.html.raw');

    spyOn(urlUtils, 'visitUrl');

    response = {};

    mock = new MockAdapter(axios);

    mock.onGet(new RegExp(`${JOB_URL}/trace.json?(.*)`)).reply(() => [200, response]);
  });

  afterEach(() => {
    mock.restore();

    clearTimeout(job.timeout);
  });

  describe('class constructor', () => {
    beforeEach(() => {
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    describe('setup', () => {
      beforeEach(function (done) {
        job = new Job();

        waitForPromise()
          .then(done)
          .catch(done.fail);
      });

      it('copies build options', function () {
        expect(job.pagePath).toBe(JOB_URL);
        expect(job.buildStatus).toBe('success');
        expect(job.buildStage).toBe('test');
        expect(job.state).toBe('');
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
    });

    describe('running build', () => {
      it('updates the build trace on an interval', function (done) {
        response = {
          html: '<span>Update<span>',
          status: 'running',
          state: 'newstate',
          append: true,
          complete: false,
        };

        job = new Job();

        waitForPromise()
          .then(() => {
            expect($('#build-trace .js-build-output').text()).toMatch(/Update/);
            expect(job.state).toBe('newstate');

            response = {
              html: '<span>More</span>',
              status: 'running',
              state: 'finalstate',
              append: true,
              complete: true,
            };
          })
          .then(() => jasmine.clock().tick(4001))
          .then(waitForPromise)
          .then(() => {
            expect($('#build-trace .js-build-output').text()).toMatch(/UpdateMore/);
            expect(job.state).toBe('finalstate');
          })
          .then(done)
          .catch(done.fail);
      });

      it('replaces the entire build trace', (done) => {
        response = {
          html: '<span>Update<span>',
          status: 'running',
          append: false,
          complete: false,
        };

        job = new Job();

        waitForPromise()
          .then(() => {
            expect($('#build-trace .js-build-output').text()).toMatch(/Update/);

            response = {
              html: '<span>Different</span>',
              status: 'running',
              append: false,
            };
          })
          .then(() => jasmine.clock().tick(4001))
          .then(waitForPromise)
          .then(() => {
            expect($('#build-trace .js-build-output').text()).not.toMatch(/Update/);
            expect($('#build-trace .js-build-output').text()).toMatch(/Different/);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('truncated information', () => {
      describe('when size is less than total', () => {
        it('shows information about truncated log', (done) => {
          response = {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          };

          job = new Job();

          waitForPromise()
            .then(() => {
              expect(document.querySelector('.js-truncated-info').classList).not.toContain('hidden');
            })
            .then(done)
            .catch(done.fail);
        });

        it('shows the size in KiB', (done) => {
          const size = 50;

          response = {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size,
            total: 100,
          };

          job = new Job();

          waitForPromise()
            .then(() => {
              expect(
                document.querySelector('.js-truncated-info-size').textContent.trim(),
              ).toEqual(`${numberToHumanSize(size)}`);
            })
            .then(done)
            .catch(done.fail);
        });

        it('shows incremented size', (done) => {
          response = {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
            complete: false,
          };

          job = new Job();

          waitForPromise()
            .then(() => {
              expect(
                document.querySelector('.js-truncated-info-size').textContent.trim(),
              ).toEqual(`${numberToHumanSize(50)}`);

              response = {
                html: '<span>Update</span>',
                status: 'success',
                append: true,
                size: 10,
                total: 100,
                complete: true,
              };
            })
            .then(() => jasmine.clock().tick(4001))
            .then(waitForPromise)
            .then(() => {
              expect(
                document.querySelector('.js-truncated-info-size').textContent.trim(),
              ).toEqual(`${numberToHumanSize(60)}`);
            })
            .then(done)
            .catch(done.fail);
        });

        it('renders the raw link', () => {
          response = {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 50,
            total: 100,
          };

          job = new Job();

          expect(
            document.querySelector('.js-raw-link').textContent.trim(),
          ).toContain('Complete Raw');
        });
      });

      describe('when size is equal than total', () => {
        it('does not show the trunctated information', (done) => {
          response = {
            html: '<span>Update</span>',
            status: 'success',
            append: false,
            size: 100,
            total: 100,
          };

          job = new Job();

          waitForPromise()
            .then(() => {
              expect(document.querySelector('.js-truncated-info').classList).toContain('hidden');
            })
            .then(done)
            .catch(done.fail);
        });
      });
    });

    describe('output trace', () => {
      beforeEach((done) => {
        response = {
          html: '<span>Update</span>',
          status: 'success',
          append: false,
          size: 50,
          total: 100,
        };

        job = new Job();

        waitForPromise()
          .then(done)
          .catch(done.fail);
      });

      it('should render trace controls', () => {
        const controllers = document.querySelector('.controllers');

        expect(controllers.querySelector('.js-raw-link-controller')).not.toBeNull();
        expect(controllers.querySelector('.js-scroll-up')).not.toBeNull();
        expect(controllers.querySelector('.js-scroll-down')).not.toBeNull();
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
      spyOn(axios, 'get').and.callThrough();
      // eslint-disable-next-line no-new
      job = new Job();

      setTimeout(() => {
        expect(axios.get).toHaveBeenCalledWith(
          `${JOB_URL}/trace.json`, { params: { state: '' } },
        );
        done();
      }, 0);
    });
  });
});
