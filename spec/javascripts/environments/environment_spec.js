const Vue = require('vue');
require('~/flash');
const EnvironmentsComponent = require('~/environments/components/environment');
const { environment } = require('./mock_data');

describe('Environment', () => {
  preloadFixtures('static/environments/environments.html.raw');

  let component;

  beforeEach(() => {
    loadFixtures('static/environments/environments.html.raw');
  });

  describe('successfull request', () => {
    describe('without environments', () => {
      const environmentsEmptyResponseInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(environmentsEmptyResponseInterceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, environmentsEmptyResponseInterceptor,
        );
      });

      it('should render the empty state', (done) => {
        component = new EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
        });

        setTimeout(() => {
          expect(
            component.$el.querySelector('.js-new-environment-button').textContent,
          ).toContain('New Environment');

          expect(
            component.$el.querySelector('.js-blank-state-title').textContent,
          ).toContain('You don\'t have any environments right now.');

          done();
        }, 0);
      });
    });

    describe('with environments', () => {
      const environmentsResponseInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify({
          environments: [environment],
          stopped_count: 1,
          available_count: 0,
        }), {
          status: 200,
          headers: {
            'X-nExt-pAge': '2',
            'x-page': '1',
            'X-Per-Page': '1',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '2',
          },
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(environmentsResponseInterceptor);
        component = new EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
        });
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, environmentsResponseInterceptor,
        );
      });

      it('should render a table with environments', (done) => {
        setTimeout(() => {
          expect(
            component.$el.querySelectorAll('table tbody tr').length,
          ).toEqual(1);
          done();
        }, 0);
      });

      describe('pagination', () => {
        it('should render pagination', (done) => {
          setTimeout(() => {
            expect(
              component.$el.querySelectorAll('.gl-pagination li').length,
            ).toEqual(5);
            done();
          }, 0);
        });

        it('should update url when no search params are present', (done) => {
          spyOn(gl.utils, 'visitUrl');
          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) a').click();
            expect(gl.utils.visitUrl).toHaveBeenCalledWith('?page=2');
            done();
          }, 0);
        });

        it('should update url when page is already present', (done) => {
          spyOn(gl.utils, 'visitUrl');
          window.history.pushState({}, null, '?page=1');

          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) a').click();
            expect(gl.utils.visitUrl).toHaveBeenCalledWith('?page=2');
            done();
          }, 0);
        });

        it('should update url when page and scope are already present', (done) => {
          spyOn(gl.utils, 'visitUrl');
          window.history.pushState({}, null, '?scope=all&page=1');

          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) a').click();
            expect(gl.utils.visitUrl).toHaveBeenCalledWith('?scope=all&page=2');
            done();
          }, 0);
        });

        it('should update url when page and scope are already present and page is first param', (done) => {
          spyOn(gl.utils, 'visitUrl');
          window.history.pushState({}, null, '?page=1&scope=all');

          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) a').click();
            expect(gl.utils.visitUrl).toHaveBeenCalledWith('?page=2&scope=all');
            done();
          }, 0);
        });
      });

      describe('deploy boards', () => {
        it('should render arrow to open deploy boards', (done) => {
          setTimeout(() => {
            expect(
              component.$el.querySelector('.deploy-board-icon i').classList.contains('fa-caret-right'),
            ).toEqual(true);
            done();
          }, 0);
        });
      });
    });
  });

  describe('unsuccessfull request', () => {
    const environmentsErrorResponseInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 500,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(environmentsErrorResponseInterceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, environmentsErrorResponseInterceptor,
      );
    });

    it('should render empty state', (done) => {
      component = new EnvironmentsComponent({
        el: document.querySelector('#environments-list-view'),
      });

      setTimeout(() => {
        expect(
          component.$el.querySelector('.js-blank-state-title').textContent,
        ).toContain('You don\'t have any environments right now.');
        done();
      }, 0);
    });
  });
});
