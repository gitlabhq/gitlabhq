import _ from 'underscore';
import Vue from 'vue';
import pipelinesComp from '~/pipelines/components/pipelines.vue';
import Store from '~/pipelines/stores/pipelines_store';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Pipelines', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';

  preloadFixtures('static/pipelines.html.raw');
  preloadFixtures(jsonFixtureName);

  let PipelinesComponent;
  let pipelines;
  let component;

  beforeEach(() => {
    loadFixtures('static/pipelines.html.raw');
    pipelines = getJSONFixture(jsonFixtureName);

    PipelinesComponent = Vue.extend(pipelinesComp);
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('successfull request', () => {
    describe('with pipelines', () => {
      const pipelinesInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify(pipelines), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(pipelinesInterceptor);
        component = mountComponent(PipelinesComponent, {
          store: new Store(),
        });
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, pipelinesInterceptor,
        );
      });

      it('should render table', (done) => {
        setTimeout(() => {
          expect(component.$el.querySelector('.table-holder')).toBeDefined();
          expect(
            component.$el.querySelectorAll('.gl-responsive-table-row').length,
          ).toEqual(pipelines.pipelines.length + 1);
          done();
        });
      });

      it('should render navigation tabs', (done) => {
        setTimeout(() => {
          expect(
            component.$el.querySelector('.js-pipelines-tab-pending').textContent.trim(),
          ).toContain('Pending');
          expect(
            component.$el.querySelector('.js-pipelines-tab-all').textContent.trim(),
          ).toContain('All');
          expect(
            component.$el.querySelector('.js-pipelines-tab-running').textContent.trim(),
          ).toContain('Running');
          expect(
            component.$el.querySelector('.js-pipelines-tab-finished').textContent.trim(),
          ).toContain('Finished');
          expect(
            component.$el.querySelector('.js-pipelines-tab-branches').textContent.trim(),
          ).toContain('Branches');
          expect(
            component.$el.querySelector('.js-pipelines-tab-tags').textContent.trim(),
          ).toContain('Tags');
          done();
        });
      });

      it('should make an API request when using tabs', (done) => {
        setTimeout(() => {
          spyOn(component, 'updateContent');
          component.$el.querySelector('.js-pipelines-tab-finished').click();

          expect(component.updateContent).toHaveBeenCalledWith({ scope: 'finished', page: '1' });
          done();
        });
      });

      describe('with pagination', () => {
        it('should make an API request when using pagination', (done) => {
          setTimeout(() => {
            spyOn(component, 'updateContent');
            // Mock pagination
            component.store.state.pageInfo = {
              page: 1,
              total: 10,
              perPage: 2,
              nextPage: 2,
              totalPages: 5,
            };

            Vue.nextTick(() => {
              component.$el.querySelector('.js-next-button a').click();
              expect(component.updateContent).toHaveBeenCalledWith({ scope: 'all', page: '2' });

              done();
            });
          });
        });
      });
    });

    describe('without pipelines', () => {
      const emptyInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(emptyInterceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors, emptyInterceptor,
        );
      });

      it('should render empty state', (done) => {
        component = new PipelinesComponent({
          propsData: {
            store: new Store(),
          },
        }).$mount();

        setTimeout(() => {
          expect(component.$el.querySelector('.empty-state')).not.toBe(null);
          done();
        });
      });
    });
  });

  describe('unsuccessfull request', () => {
    const errorInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 500,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(errorInterceptor);
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(
        Vue.http.interceptors, errorInterceptor,
      );
    });

    it('should render error state', (done) => {
      component = new PipelinesComponent({
        propsData: {
          store: new Store(),
        },
      }).$mount();

      setTimeout(() => {
        expect(component.$el.querySelector('.js-pipelines-error-state')).toBeDefined();
        done();
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      spyOn(history, 'pushState').and.stub();
    });

    describe('updateContent', () => {
      it('should set given parameters', () => {
        component = mountComponent(PipelinesComponent, {
          store: new Store(),
        });
        component.updateContent({ scope: 'finished', page: '4' });

        expect(component.page).toEqual('4');
        expect(component.scope).toEqual('finished');
        expect(component.requestData.scope).toEqual('finished');
        expect(component.requestData.page).toEqual('4');
      });
    });

    describe('onChangeTab', () => {
      it('should set page to 1', () => {
        component = mountComponent(PipelinesComponent, {
          store: new Store(),
        });

        spyOn(component, 'updateContent');

        component.onChangeTab('running');

        expect(component.updateContent).toHaveBeenCalledWith({ scope: 'running', page: '1' });
      });
    });

    describe('onChangePage', () => {
      it('should update page and keep scope', () => {
        component = mountComponent(PipelinesComponent, {
          store: new Store(),
        });

        spyOn(component, 'updateContent');

        component.onChangePage(4);

        expect(component.updateContent).toHaveBeenCalledWith({ scope: component.scope, page: '4' });
      });
    });
  });
});
