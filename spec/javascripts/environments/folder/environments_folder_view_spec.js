import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { removeBreakLine, removeWhitespace } from 'spec/helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import environmentsFolderViewComponent from '~/environments/folder/environments_folder_view.vue';
import { environmentsList } from '../mock_data';

describe('Environments Folder View', () => {
  let Component;
  let component;
  let mock;

  const mockData = {
    endpoint: 'environments.json',
    folderName: 'review',
    canReadEnvironment: true,
    cssContainerClass: 'container',
    canaryDeploymentFeatureId: 'canary_deployment',
    showCanaryDeploymentCallout: true,
    userCalloutsPath: '/callouts',
    lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
    helpCanaryDeploymentsPath: 'help/canary-deployments',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    Component = Vue.extend(environmentsFolderViewComponent);
  });

  afterEach(() => {
    mock.restore();

    component.$destroy();
  });

  describe('successful request', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(
        200,
        {
          environments: environmentsList,
          stopped_count: 1,
          available_count: 0,
        },
        {
          'X-nExt-pAge': '2',
          'x-page': '1',
          'X-Per-Page': '2',
          'X-Prev-Page': '',
          'X-TOTAL': '20',
          'X-Total-Pages': '10',
        },
      );

      component = mountComponent(Component, mockData);
    });

    it('should render a table with environments', done => {
      setTimeout(() => {
        expect(component.$el.querySelectorAll('table')).not.toBeNull();
        expect(component.$el.querySelector('.environment-name').textContent.trim()).toEqual(
          environmentsList[0].name,
        );
        done();
      }, 0);
    });

    it('should render available tab with count', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-environments-tab-available').textContent).toContain(
          'Available',
        );

        expect(
          component.$el.querySelector('.js-environments-tab-available .badge').textContent,
        ).toContain('0');
        done();
      }, 0);
    });

    it('should render stopped tab with count', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-environments-tab-stopped').textContent).toContain(
          'Stopped',
        );

        expect(
          component.$el.querySelector('.js-environments-tab-stopped .badge').textContent,
        ).toContain('1');
        done();
      }, 0);
    });

    it('should render parent folder name', done => {
      setTimeout(() => {
        expect(
          removeBreakLine(
            removeWhitespace(component.$el.querySelector('.js-folder-name').textContent.trim()),
          ),
        ).toContain('Environments / review');
        done();
      }, 0);
    });

    describe('pagination', () => {
      it('should render pagination', done => {
        setTimeout(() => {
          expect(component.$el.querySelectorAll('.gl-pagination')).not.toBeNull();
          done();
        }, 0);
      });

      it('should make an API request when changing page', done => {
        spyOn(component, 'updateContent');
        setTimeout(() => {
          component.$el.querySelector('.gl-pagination .js-last-button .page-link').click();

          expect(component.updateContent).toHaveBeenCalledWith({
            scope: component.scope,
            page: '10',
          });
          done();
        }, 0);
      });

      it('should make an API request when using tabs', done => {
        setTimeout(() => {
          spyOn(component, 'updateContent');
          component.$el.querySelector('.js-environments-tab-stopped').click();

          expect(component.updateContent).toHaveBeenCalledWith({ scope: 'stopped', page: '1' });
          done();
        });
      });
    });
  });

  describe('unsuccessfull request', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(500, {
        environments: [],
      });

      component = mountComponent(Component, mockData);
    });

    it('should not render a table', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('table')).toBe(null);
        done();
      }, 0);
    });

    it('should render available tab with count 0', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-environments-tab-available').textContent).toContain(
          'Available',
        );

        expect(
          component.$el.querySelector('.js-environments-tab-available .badge').textContent,
        ).toContain('0');
        done();
      }, 0);
    });

    it('should render stopped tab with count 0', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-environments-tab-stopped').textContent).toContain(
          'Stopped',
        );

        expect(
          component.$el.querySelector('.js-environments-tab-stopped .badge').textContent,
        ).toContain('0');
        done();
      }, 0);
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(200, {
        environments: [],
      });

      component = mountComponent(Component, mockData);
      spyOn(window.history, 'pushState').and.stub();
    });

    describe('updateContent', () => {
      it('should set given parameters', done => {
        component
          .updateContent({ scope: 'stopped', page: '4' })
          .then(() => {
            expect(component.page).toEqual('4');
            expect(component.scope).toEqual('stopped');
            expect(component.requestData.scope).toEqual('stopped');
            expect(component.requestData.page).toEqual('4');
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
