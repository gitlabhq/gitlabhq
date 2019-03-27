import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import axios from '~/lib/utils/axios_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint, environmentData } from './mock_data';

const propsData = {
  hasMetrics: false,
  documentationPath: '/path/to/docs',
  settingsPath: '/path/to/settings',
  clustersPath: '/path/to/clusters',
  tagsPath: '/path/to/tags',
  projectPath: '/path/to/project',
  metricsEndpoint: mockApiEndpoint,
  deploymentEndpoint: null,
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  environmentsEndpoint: '/root/hello-prometheus/environments/35',
  currentEnvironmentName: 'production',
};

export default propsData;

describe('Dashboard', () => {
  let DashboardComponent;
  let mock;

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);

    mock = new MockAdapter(axios);
    DashboardComponent = Vue.extend(Dashboard);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('no metrics are available yet', () => {
    it('shows a getting started empty state when no metrics are present', () => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData,
      });

      expect(component.$el.querySelector('.prometheus-graphs')).toBe(null);
      expect(component.state).toEqual('gettingStarted');
    });
  });

  describe('requests information to the server', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    it('shows up a loading state', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
      });

      Vue.nextTick(() => {
        expect(component.state).toEqual('loading');
        done();
      });
    });

    it('hides the legend when showLegend is false', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showLegend: false },
      });

      setTimeout(() => {
        expect(component.showEmptyState).toEqual(false);
        expect(component.$el.querySelector('.legend-group')).toEqual(null);
        expect(component.$el.querySelector('.prometheus-graph-group')).toBeTruthy();
        done();
      });
    });

    it('hides the group panels when showPanels is false', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      setTimeout(() => {
        expect(component.showEmptyState).toEqual(false);
        expect(component.$el.querySelector('.prometheus-panel')).toEqual(null);
        expect(component.$el.querySelector('.prometheus-graph-group')).toBeTruthy();
        done();
      });
    });

    it('renders the environments dropdown with a number of environments', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      component.store.storeEnvironmentsData(environmentData);

      setTimeout(() => {
        const dropdownMenuEnvironments = component.$el.querySelectorAll(
          '.js-environments-dropdown .dropdown-item',
        );

        expect(dropdownMenuEnvironments.length).toEqual(component.store.environmentsData.length);
        done();
      });
    });

    it('hides the environments dropdown list when there is no environments', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      component.store.storeEnvironmentsData([]);

      setTimeout(() => {
        const dropdownMenuEnvironments = component.$el.querySelectorAll(
          '.js-environments-dropdown .dropdown-item',
        );

        expect(dropdownMenuEnvironments.length).toEqual(0);
        done();
      });
    });

    it('renders the environments dropdown with a single is-active element', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      component.store.storeEnvironmentsData(environmentData);

      setTimeout(() => {
        const dropdownItems = component.$el.querySelectorAll(
          '.js-environments-dropdown .dropdown-item[active="true"]',
        );

        expect(dropdownItems.length).toEqual(1);
        expect(dropdownItems[0].textContent.trim()).toEqual(component.currentEnvironmentName);
        done();
      });
    });
  });

  describe('when the window resizes', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
    });

    it('sets elWidth to page width when the sidebar is resized', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      expect(component.elWidth).toEqual(0);

      const pageLayoutEl = document.querySelector('.layout-page');
      pageLayoutEl.classList.add('page-with-icon-sidebar');

      Vue.nextTick()
        .then(() => {
          jasmine.clock().tick(1000);
          return Vue.nextTick();
        })
        .then(() => {
          expect(component.elWidth).toEqual(pageLayoutEl.clientWidth);
          done();
        })
        .catch(done.fail);
    });
  });
});
