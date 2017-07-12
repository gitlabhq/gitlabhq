import Vue from 'vue';
import '~/flash';
import environmentsComponent from '~/environments/components/environment.vue';
import { environment, folder } from './mock_data';
import { headersInterceptor } from '../helpers/vue_resource_helper';

describe('Environment', () => {
  preloadFixtures('static/environments/environments.html.raw');

  let EnvironmentsComponent;
  let component;

  beforeEach(() => {
    loadFixtures('static/environments/environments.html.raw');

    EnvironmentsComponent = Vue.extend(environmentsComponent);
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
        Vue.http.interceptors.push(headersInterceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, environmentsEmptyResponseInterceptor,
        );
        Vue.http.interceptors = _.without(Vue.http.interceptors, headersInterceptor);
      });

      it('should render the empty state', (done) => {
        component = new EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
        });

        setTimeout(() => {
          expect(
            component.$el.querySelector('.js-new-environment-button').textContent,
          ).toContain('New environment');

          expect(
            component.$el.querySelector('.js-blank-state-title').textContent,
          ).toContain('You don\'t have any environments right now.');

          done();
        }, 0);
      });
    });

    describe('with environments', () => {
      const environmentsResponseInterceptor = (request, next) => {
        next((response) => {
          response.headers.set('X-nExt-pAge', '2');
        });

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
        Vue.http.interceptors.push(headersInterceptor);
        component = new EnvironmentsComponent({
          el: document.querySelector('#environments-list-view'),
        });
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, environmentsResponseInterceptor,
        );
        Vue.http.interceptors = _.without(Vue.http.interceptors, headersInterceptor);
      });

      it('should render a table with environments', (done) => {
        setTimeout(() => {
          expect(component.$el.querySelectorAll('table')).toBeDefined();
          expect(
            component.$el.querySelector('.environment-name').textContent.trim(),
          ).toEqual(environment.name);
          done();
        }, 0);
      });

      describe('pagination', () => {
        afterEach(() => {
          window.history.pushState({}, null, '');
        });

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
              component.$el.querySelector('.deploy-board-icon i.fa-caret-right'),
            ).toBeDefined();
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

  describe('expandable folders', () => {
    const environmentsResponseInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify({
        environments: [folder],
        stopped_count: 0,
        available_count: 1,
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

    it('should open a closed folder', (done) => {
      setTimeout(() => {
        component.$el.querySelector('.folder-name').click();

        Vue.nextTick(() => {
          expect(
            component.$el.querySelector('.folder-icon i.fa-caret-right').getAttribute('style'),
          ).toContain('display: none');
          expect(
            component.$el.querySelector('.folder-icon i.fa-caret-down').getAttribute('style'),
          ).not.toContain('display: none');
          done();
        });
      });
    });

    it('should close an opened folder', (done) => {
      setTimeout(() => {
        // open folder
        component.$el.querySelector('.folder-name').click();

        Vue.nextTick(() => {
          // close folder
          component.$el.querySelector('.folder-name').click();

          Vue.nextTick(() => {
            expect(
              component.$el.querySelector('.folder-icon i.fa-caret-down').getAttribute('style'),
            ).toContain('display: none');
            expect(
              component.$el.querySelector('.folder-icon i.fa-caret-right').getAttribute('style'),
            ).not.toContain('display: none');
            done();
          });
        });
      });
    });

    it('should show children environments and a button to show all environments', (done) => {
      setTimeout(() => {
        // open folder
        component.$el.querySelector('.folder-name').click();

        Vue.nextTick(() => {
          const folderInterceptor = (request, next) => {
            next(request.respondWith(JSON.stringify({
              environments: [environment],
            }), { status: 200 }));
          };

          Vue.http.interceptors.push(folderInterceptor);

          // wait for next async request
          setTimeout(() => {
            expect(component.$el.querySelectorAll('.js-child-row').length).toEqual(1);
            expect(component.$el.querySelector('.text-center > a.btn').textContent).toContain('Show all');

            Vue.http.interceptors = _.without(Vue.http.interceptors, folderInterceptor);
            done();
          });
        });
      });
    });
  });
});
