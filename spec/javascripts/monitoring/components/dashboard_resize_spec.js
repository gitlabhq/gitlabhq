import Vue from 'vue';
import { createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import * as types from '~/monitoring/stores/mutation_types';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';
import {
  metricsGroupsAPIResponse,
  mockedEmptyResult,
  mockedQueryResultPayload,
  mockedQueryResultPayloadCoresTotal,
  mockApiEndpoint,
  environmentData,
} from '../mock_data';

const localVue = createLocalVue();
const propsData = {
  hasMetrics: false,
  documentationPath: '/path/to/docs',
  settingsPath: '/path/to/settings',
  clustersPath: '/path/to/clusters',
  tagsPath: '/path/to/tags',
  projectPath: '/path/to/project',
  metricsEndpoint: mockApiEndpoint,
  deploymentsEndpoint: null,
  emptyGettingStartedSvgPath: '/path/to/getting-started.svg',
  emptyLoadingSvgPath: '/path/to/loading.svg',
  emptyNoDataSvgPath: '/path/to/no-data.svg',
  emptyNoDataSmallSvgPath: '/path/to/no-data-small.svg',
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  environmentsEndpoint: '/root/hello-prometheus/environments/35',
  currentEnvironmentName: 'production',
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
};

function setupComponentStore(component) {
  // Load 2 panel groups
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
    metricsGroupsAPIResponse,
  );

  // Load 3 panels to the dashboard, one with an empty result
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
    mockedEmptyResult,
  );
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
    mockedQueryResultPayload,
  );
  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_METRIC_RESULT_SUCCESS}`,
    mockedQueryResultPayloadCoresTotal,
  );

  component.$store.commit(
    `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
    environmentData,
  );
}

describe('Dashboard', () => {
  let DashboardComponent;
  let mock;
  let store;
  let component;
  let wrapper;

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);

    store = createStore();
    mock = new MockAdapter(axios);
    DashboardComponent = localVue.extend(Dashboard);
  });

  afterEach(() => {
    if (component) {
      component.$destroy();
    }
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
  });

  describe('responds to window resizes', () => {
    let promPanel;
    let promGroup;
    let panelToggle;
    let chart;
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: true,
        },
        store,
      });

      setupComponentStore(component);

      return Vue.nextTick().then(() => {
        [, promPanel] = component.$el.querySelectorAll('.prometheus-panel');
        promGroup = promPanel.querySelector('.prometheus-graph-group');
        panelToggle = promPanel.querySelector('.js-graph-group-toggle');
        chart = promGroup.querySelector('.position-relative svg');
      });
    });

    it('setting chart size to zero when panel group is hidden', () => {
      expect(promGroup.style.display).toBe('');
      expect(chart.clientWidth).toBeGreaterThan(0);

      panelToggle.click();
      return Vue.nextTick().then(() => {
        expect(promGroup.style.display).toBe('none');
        expect(chart.clientWidth).toBe(0);
        promPanel.style.width = '500px';
      });
    });

    it('expanding chart panel group after resize displays chart', () => {
      panelToggle.click();

      expect(chart.clientWidth).toBeGreaterThan(0);
    });
  });
});
