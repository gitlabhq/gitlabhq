import Vue from 'vue';
import { createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';
import { mockApiEndpoint, propsData } from '../mock_data';
import { metricsDashboardPayload } from '../fixture_data';
import { setupStoreWithData } from '../store_utils';

const localVue = createLocalVue();

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
      mock.onGet(mockApiEndpoint).reply(200, metricsDashboardPayload);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: true,
        },
        store,
      });

      setupStoreWithData(component.$store);

      return Vue.nextTick().then(() => {
        [promPanel] = component.$el.querySelectorAll('.prometheus-panel');
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
