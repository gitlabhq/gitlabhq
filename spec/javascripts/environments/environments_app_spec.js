import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import environmentsComponent from '~/environments/components/environments_app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { environment, folder } from './mock_data';

describe('Environment', () => {
  const mockData = {
    endpoint: 'environments.json',
    canCreateEnvironment: true,
    canReadEnvironment: true,
    newEnvironmentPath: 'environments/new',
    helpPagePath: 'help',
    canaryDeploymentFeatureId: 'canary_deployment',
    showCanaryDeploymentCallout: true,
    userCalloutsPath: '/callouts',
    lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
    helpCanaryDeploymentsPath: 'help/canary-deployments',
  };

  let EnvironmentsComponent;
  let component;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    EnvironmentsComponent = Vue.extend(environmentsComponent);
  });

  afterEach(() => {
    component.$destroy();
    mock.restore();
  });

  describe('successful request', () => {
    describe('without environments', () => {
      beforeEach(done => {
        mock.onGet(mockData.endpoint).reply(200, { environments: [] });

        component = mountComponent(EnvironmentsComponent, mockData);

        setTimeout(() => {
          done();
        }, 0);
      });

      it('should render the empty state', () => {
        expect(component.$el.querySelector('.js-new-environment-button').textContent).toContain(
          'New environment',
        );

        expect(component.$el.querySelector('.js-blank-state-title').textContent).toContain(
          "You don't have any environments right now",
        );
      });
    });

    describe('with paginated environments', () => {
      beforeEach(done => {
        mock.onGet(mockData.endpoint).reply(
          200,
          {
            environments: [environment],
            stopped_count: 1,
            available_count: 0,
          },
          {
            'X-nExt-pAge': '2',
            'x-page': '1',
            'X-Per-Page': '1',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '2',
          },
        );

        component = mountComponent(EnvironmentsComponent, mockData);

        setTimeout(() => {
          done();
        }, 0);
      });

      it('should render a table with environments', () => {
        expect(component.$el.querySelectorAll('table')).not.toBeNull();
        expect(component.$el.querySelector('.environment-name').textContent.trim()).toEqual(
          environment.name,
        );
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(component.$el.querySelectorAll('.gl-pagination li').length).toEqual(5);
        });

        it('should make an API request when page is clicked', done => {
          spyOn(component, 'updateContent');
          setTimeout(() => {
            component.$el.querySelector('.gl-pagination li:nth-child(5) .page-link').click();

            expect(component.updateContent).toHaveBeenCalledWith({ scope: 'available', page: '2' });
            done();
          }, 0);
        });

        it('should make an API request when using tabs', done => {
          setTimeout(() => {
            spyOn(component, 'updateContent');
            component.$el.querySelector('.js-environments-tab-stopped').click();

            expect(component.updateContent).toHaveBeenCalledWith({ scope: 'stopped', page: '1' });
            done();
          }, 0);
        });
      });
    });
  });

  describe('unsuccessfull request', () => {
    beforeEach(done => {
      mock.onGet(mockData.endpoint).reply(500, {});

      component = mountComponent(EnvironmentsComponent, mockData);

      setTimeout(() => {
        done();
      }, 0);
    });

    it('should render empty state', () => {
      expect(component.$el.querySelector('.js-blank-state-title').textContent).toContain(
        "You don't have any environments right now",
      );
    });
  });

  describe('expandable folders', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(
        200,
        {
          environments: [folder],
          stopped_count: 0,
          available_count: 1,
        },
        {
          'X-nExt-pAge': '2',
          'x-page': '1',
          'X-Per-Page': '1',
          'X-Prev-Page': '',
          'X-TOTAL': '37',
          'X-Total-Pages': '2',
        },
      );

      mock.onGet(environment.folder_path).reply(200, { environments: [environment] });

      component = mountComponent(EnvironmentsComponent, mockData);
    });

    it('should open a closed folder', done => {
      setTimeout(() => {
        component.$el.querySelector('.folder-name').click();

        Vue.nextTick(() => {
          expect(component.$el.querySelector('.folder-icon.ic-chevron-right')).toBe(null);
          done();
        });
      }, 0);
    });

    it('should close an opened folder', done => {
      setTimeout(() => {
        // open folder
        component.$el.querySelector('.folder-name').click();

        Vue.nextTick(() => {
          // close folder
          component.$el.querySelector('.folder-name').click();

          Vue.nextTick(() => {
            expect(component.$el.querySelector('.folder-icon.ic-chevron-down')).toBe(null);
            done();
          });
        });
      }, 0);
    });

    it('should show children environments and a button to show all environments', done => {
      setTimeout(() => {
        // open folder
        component.$el.querySelector('.folder-name').click();

        Vue.nextTick(() => {
          // wait for next async request
          setTimeout(() => {
            expect(component.$el.querySelectorAll('.js-child-row').length).toEqual(1);
            expect(component.$el.querySelector('.text-center > a.btn').textContent).toContain(
              'Show all',
            );
            done();
          });
        });
      }, 0);
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(
        200,
        {
          environments: [],
          stopped_count: 0,
          available_count: 1,
        },
        {},
      );

      component = mountComponent(EnvironmentsComponent, mockData);
      spyOn(window.history, 'pushState').and.stub();
    });

    describe('updateContent', () => {
      it('should set given parameters', done => {
        component
          .updateContent({ scope: 'stopped', page: '3' })
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
