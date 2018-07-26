import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import axios from '~/lib/utils/axios_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint, environmentData } from './mock_data';

describe('Dashboard', () => {
  let DashboardComponent;

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
    showEnvironmentDropdown: true,
  };

  beforeEach(() => {
    setFixtures('<div class="prometheus-graphs"></div>');
    DashboardComponent = Vue.extend(Dashboard);
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
    let mock;
    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    afterEach(() => {
      mock.restore();
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

    it('renders the dropdown with a number of environments', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      component.store.storeEnvironmentsData(environmentData);

      setTimeout(() => {
        const dropdownMenuEnvironments = component.$el.querySelectorAll('.dropdown-menu ul li a');
        expect(dropdownMenuEnvironments.length).toEqual(component.store.environmentsData.length);
        done();
      });
    });

    it('renders the dropdown with a single is-active element', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showPanels: false },
      });

      component.store.storeEnvironmentsData(environmentData);

      setTimeout(() => {
        const dropdownIsActiveElement = component.$el.querySelectorAll(
          '.dropdown-menu ul li a.is-active',
        );
        expect(dropdownIsActiveElement.length).toEqual(1);
        expect(dropdownIsActiveElement[0].textContent.trim()).toEqual(
          component.currentEnvironmentName,
        );
        done();
      });
    });

    it('hides the dropdown', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showEnvironmentDropdown: false,
        },
      });

      Vue.nextTick(() => {
        const dropdownIsActiveElement = component.$el.querySelectorAll('.environments');
        expect(dropdownIsActiveElement.length).toEqual(0);
        done();
      });
    });
  });
});
