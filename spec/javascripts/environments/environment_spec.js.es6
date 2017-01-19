/* global Vue, environment */

//= require vue
//= require vue-resource
//= require flash
//= require environments/stores/environments_store
//= require environments/components/environment
//= require ./mock_data

describe('Environment', () => {
  preloadFixtures('environments/environments');

  let component;

  beforeEach(() => {
    loadFixtures('environments/environments');
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
        component = new gl.environmentsList.EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
          propsData: {
            store: gl.environmentsList.EnvironmentsStore.create(),
          },
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
        next(request.respondWith(JSON.stringify([environment]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(environmentsResponseInterceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, environmentsResponseInterceptor,
        );
      });

      it('should render a table with environments', (done) => {
        component = new gl.environmentsList.EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
          propsData: {
            store: gl.environmentsList.EnvironmentsStore.create(),
          },
        });

        setTimeout(() => {
          expect(
            component.$el.querySelectorAll('table tbody tr').length,
          ).toEqual(1);
          done();
        }, 0);
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
      component = new gl.environmentsList.EnvironmentsComponent({
        el: document.querySelector('#environments-list-view'),
        propsData: {
          store: gl.environmentsList.EnvironmentsStore.create(),
        },
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
