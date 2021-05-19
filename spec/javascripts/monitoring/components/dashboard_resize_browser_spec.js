/**
 * This file should only contain browser specific specs.
 * If you need to add or update a spec, please see spec/frontend/monitoring/components/*.js
 * https://gitlab.com/gitlab-org/gitlab/-/issues/194244#note_343427737
 * https://gitlab.com/groups/gitlab-org/-/epics/895#what-if-theres-a-karma-spec-which-is-simply-unmovable-to-jest-ie-it-is-dependent-on-a-running-browser-environment
 */

import { createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import { metricsDashboardPayload, dashboardProps } from '../fixture_data';
import { mockApiEndpoint } from '../mock_data';
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
          ...dashboardProps,
          hasMetrics: true,
          showPanels: true,
        },
        store,
        provide: { hasManagedPrometheus: false },
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
