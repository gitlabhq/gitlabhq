import _ from 'underscore';
import Vue from 'vue';
import environmentsComponent from '~/environments/components/environments_app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { headersInterceptor } from 'spec/helpers/vue_resource_helper';
import { environment, folder } from './mock_data';

describe('Environment', () => {
  const mockData = {
    endpoint: 'environments.json',
    canCreateEnvironment: true,
    canCreateDeployment: true,
    canReadEnvironment: true,
    cssContainerClass: 'container',
    newEnvironmentPath: 'environments/new',
    helpPagePath: 'help',
  };

  let EnvironmentsComponent;
  let component;

  beforeEach(() => {
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
        component = mountComponent(EnvironmentsComponent, mockData);

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

    describe('with paginated environments', () => {
      let backupInterceptors;
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
        backupInterceptors = Vue.http.interceptors;
        Vue.http.interceptors = [
          environmentsResponseInterceptor,
          headersInterceptor,
        ];
        component = mountComponent(EnvironmentsComponent, mockData);
      });

      afterEach(() => {
        Vue.http.interceptors = backupInterceptors;
      });

      it('should render a table with environments', (done) => {
        setTimeout(() => {
          expect(component.$el.querySelectorAll('table')).not.toBeNull();
          expect(
            component.$el.querySelector('.environment-name').textContent.trim(),
          ).toEqual(environment.name);
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

        it('should make an API request when page is clicked', (done) => {
          spyOn(component, 'updateContent');
          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) a').click();
            expect(component.updateContent).toHaveBeenCalledWith({ scope: 'available', page: '2' });
            done();
          }, 0);
        });

        it('should make an API request when using tabs', (done) => {
          setTimeout(() => {
            spyOn(component, 'updateContent');
            component.$el.querySelector('.js-environments-tab-stopped').click();

            expect(component.updateContent).toHaveBeenCalledWith({ scope: 'stopped', page: '1' });
            done();
          });
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
      component = mountComponent(EnvironmentsComponent, mockData);

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
      component = mountComponent(EnvironmentsComponent, mockData);
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

  describe('methods', () => {
    const environmentsEmptyResponseInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(environmentsEmptyResponseInterceptor);
      Vue.http.interceptors.push(headersInterceptor);

      component = mountComponent(EnvironmentsComponent, mockData);
      spyOn(history, 'pushState').and.stub();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, environmentsEmptyResponseInterceptor,
      );
      Vue.http.interceptors = _.without(Vue.http.interceptors, headersInterceptor);
    });

    describe('updateContent', () => {
      it('should set given parameters', (done) => {
        component.updateContent({ scope: 'stopped', page: '3' })
          .then(() => {
            expect(component.page).toEqual('3');
            expect(component.scope).toEqual('stopped');
            expect(component.requestData.scope).toEqual('stopped');
            expect(component.requestData.page).toEqual('3');
            done();
          })
          .catch(done.fail);
      });
    });

    describe('onChangeTab', () => {
      it('should set page to 1', () => {
        spyOn(component, 'updateContent');
        component.onChangeTab('stopped');

        expect(component.updateContent).toHaveBeenCalledWith({ scope: 'stopped', page: '1' });
      });
    });

    describe('onChangePage', () => {
      it('should update page and keep scope', () => {
        spyOn(component, 'updateContent');
        component.onChangePage(4);

        expect(component.updateContent).toHaveBeenCalledWith({ scope: component.scope, page: '4' });
      });
    });
  });
});
