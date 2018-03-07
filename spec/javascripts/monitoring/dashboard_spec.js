import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import axios from '~/lib/utils/axios_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint } from './mock_data';

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
    emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
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

    it('shows up a loading state', (done) => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
      });

      Vue.nextTick(() => {
        expect(component.state).toEqual('loading');
        done();
      });
    });

    it('hides the legend when showLegend is false', (done) => {
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

    it('hides the group panels when showPanels is false', (done) => {
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
  });
});
