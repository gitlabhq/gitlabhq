import Vue from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlToast } from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import * as types from '~/monitoring/stores/mutation_types';
import { createStore } from '~/monitoring/stores';
import axios from '~/lib/utils/axios_utils';
import MonitoringMock, {
  metricsGroupsAPIResponse,
  mockApiEndpoint,
  environmentData,
  singleGroupResponse,
  dashboardGitResponse,
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
  emptyUnableToConnectSvgPath: '/path/to/unable-to-connect.svg',
  environmentsEndpoint: '/root/hello-prometheus/environments/35',
  currentEnvironmentName: 'production',
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
};

const resetSpy = spy => {
  if (spy) {
    spy.calls.reset();
  }
};

export default propsData;

describe('Dashboard', () => {
  let DashboardComponent;
  let mock;
  let store;
  let component;
  let mockGraphData;

  beforeEach(() => {
    setFixtures(`
      <div class="prometheus-graphs"></div>
      <div class="layout-page"></div>
    `);

    store = createStore();
    mock = new MockAdapter(axios);
    DashboardComponent = Vue.extend(Dashboard);
  });

  afterEach(() => {
    if (component) {
      component.$destroy();
    }
    mock.restore();
  });

  describe('no metrics are available yet', () => {
    beforeEach(() => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData },
        store,
      });
    });

    it('shows a getting started empty state when no metrics are present', () => {
      expect(component.$el.querySelector('.prometheus-graphs')).toBe(null);
      expect(component.emptyState).toEqual('gettingStarted');
    });

    it('shows the environment selector', () => {
      expect(component.$el.querySelector('.js-environments-dropdown')).toBeTruthy();
    });
  });

  describe('no data found', () => {
    it('shows the environment selector dropdown', () => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, showEmptyState: true },
        store,
      });

      expect(component.$el.querySelector('.js-environments-dropdown')).toBeTruthy();
    });
  });

  describe('requests information to the server', () => {
    let spy;
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    afterEach(() => {
      resetSpy(spy);
    });

    it('shows up a loading state', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
        store,
      });

      Vue.nextTick(() => {
        expect(component.emptyState).toEqual('loading');
        done();
      });
    });

    it('hides the legend when showLegend is false', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showLegend: false,
        },
        store,
      });

      setTimeout(() => {
        expect(component.showEmptyState).toEqual(false);
        expect(component.$el.querySelector('.legend-group')).toEqual(null);
        expect(component.$el.querySelector('.prometheus-graph-group')).toBeTruthy();
        done();
      });
    });

    it('hides the group panels when showPanels is false', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      setTimeout(() => {
        expect(component.showEmptyState).toEqual(false);
        expect(component.$el.querySelector('.prometheus-panel')).toEqual(null);
        expect(component.$el.querySelector('.prometheus-graph-group')).toBeTruthy();
        done();
      });
    });

    it('renders the environments dropdown with a number of environments', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );
      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      Vue.nextTick()
        .then(() => {
          const dropdownMenuEnvironments = component.$el.querySelectorAll(
            '.js-environments-dropdown .dropdown-item',
          );

          expect(component.environments.length).toEqual(environmentData.length);
          expect(dropdownMenuEnvironments.length).toEqual(component.environments.length);

          Array.from(dropdownMenuEnvironments).forEach((value, index) => {
            if (environmentData[index].metrics_path) {
              expect(value).toHaveAttr('href', environmentData[index].metrics_path);
            }
          });

          done();
        })
        .catch(done.fail);
    });

    it('hides the environments dropdown list when there is no environments', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      component.$store.commit(`monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`, []);
      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      Vue.nextTick()
        .then(() => {
          const dropdownMenuEnvironments = component.$el.querySelectorAll(
            '.js-environments-dropdown .dropdown-item',
          );

          expect(dropdownMenuEnvironments.length).toEqual(0);
          done();
        })
        .catch(done.fail);
    });

    it('renders the environments dropdown with a single active element', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );
      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      Vue.nextTick()
        .then(() => {
          const dropdownItems = component.$el.querySelectorAll(
            '.js-environments-dropdown .dropdown-item.active',
          );

          expect(dropdownItems.length).toEqual(1);
          done();
        })
        .catch(done.fail);
    });

    it('hides the dropdown', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          environmentsEndpoint: '',
        },
        store,
      });

      Vue.nextTick(() => {
        const dropdownIsActiveElement = component.$el.querySelectorAll('.environments');

        expect(dropdownIsActiveElement.length).toEqual(0);
        done();
      });
    });

    it('renders the datetimepicker dropdown', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      setTimeout(() => {
        expect(component.$el.querySelector('.js-time-window-dropdown')).not.toBeNull();
        done();
      });
    });

    it('fetches the metrics data with proper time window', done => {
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      spyOn(component.$store, 'dispatch').and.stub();
      const getTimeDiffSpy = spyOnDependency(Dashboard, 'getTimeDiff').and.callThrough();

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );

      component.$mount();

      Vue.nextTick()
        .then(() => {
          expect(component.$store.dispatch).toHaveBeenCalled();
          expect(getTimeDiffSpy).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });

    it('shows a specific time window selected from the url params', done => {
      const start = '2019-10-01T18:27:47.000Z';
      const end = '2019-10-01T18:57:47.000Z';
      spyOnDependency(Dashboard, 'getTimeDiff').and.returnValue({
        start,
        end,
      });
      spyOnDependency(Dashboard, 'getParameterValues').and.callFake(param => {
        if (param === 'start') return [start];
        if (param === 'end') return [end];
        return [];
      });

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
        store,
      });

      setTimeout(() => {
        const selectedTimeWindow = component.$el.querySelector('.js-time-window-dropdown .active');

        expect(selectedTimeWindow.textContent.trim()).toEqual('30 minutes');
        done();
      });
    });

    it('shows an error message if invalid url parameters are passed', done => {
      spyOnDependency(Dashboard, 'getParameterValues').and.returnValue([
        '<script>alert("XSS")</script>',
      ]);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true },
        store,
      });

      spy = spyOn(component, 'showInvalidDateError');
      component.$mount();

      component.$nextTick(() => {
        expect(component.showInvalidDateError).toHaveBeenCalled();
        done();
      });
    });
  });

  describe('drag and drop function', () => {
    let wrapper;
    let expectedPanelCount; // also called metrics, naming to be improved: https://gitlab.com/gitlab-org/gitlab/issues/31565
    const findDraggables = () => wrapper.findAll(VueDraggable);
    const findEnabledDraggables = () => findDraggables().filter(f => !f.attributes('disabled'));
    const findDraggablePanels = () => wrapper.findAll('.js-draggable-panel');
    const findRearrangeButton = () => wrapper.find('.js-rearrange-button');

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
      expectedPanelCount = metricsGroupsAPIResponse.data.reduce(
        (acc, d) => d.metrics.length + acc,
        0,
      );
      store.dispatch('monitoringDashboard/setFeatureFlags', { additionalPanelTypesEnabled: true });

      wrapper = shallowMount(DashboardComponent, {
        localVue,
        sync: false,
        propsData: { ...propsData, hasMetrics: true },
        store,
      });

      // not using $nextTicket becuase we must wait for the dashboard
      // to be populated with the mock data results.
      setTimeout(done);
    });

    it('wraps vuedraggable', () => {
      expect(findDraggablePanels().exists()).toBe(true);
      expect(findDraggablePanels().length).toEqual(expectedPanelCount);
    });

    it('is disabled by default', () => {
      expect(findRearrangeButton().exists()).toBe(false);
      expect(findEnabledDraggables().length).toBe(0);
    });

    describe('when rearrange is enabled', () => {
      beforeEach(done => {
        wrapper.setProps({ rearrangePanelsAvailable: true });
        wrapper.vm.$nextTick(done);
      });

      it('displays rearrange button', () => {
        expect(findRearrangeButton().exists()).toBe(true);
      });

      describe('when rearrange button is clicked', () => {
        const findFirstDraggableRemoveButton = () =>
          findDraggablePanels()
            .at(0)
            .find('.js-draggable-remove');

        beforeEach(done => {
          findRearrangeButton().vm.$emit('click');
          wrapper.vm.$nextTick(done);
        });

        it('it enables draggables', () => {
          expect(findRearrangeButton().attributes('pressed')).toBeTruthy();
          expect(findEnabledDraggables()).toEqual(findDraggables());
        });

        it('shows a remove button, which removes a panel', done => {
          expect(findFirstDraggableRemoveButton().isEmpty()).toBe(false);

          expect(findDraggablePanels().length).toEqual(expectedPanelCount);
          findFirstDraggableRemoveButton().trigger('click');

          wrapper.vm.$nextTick(() => {
            // At present graphs will not be removed in backend
            // See https://gitlab.com/gitlab-org/gitlab/issues/27835
            expect(findDraggablePanels().length).toEqual(expectedPanelCount - 1);
            done();
          });
        });

        it('it disables draggables when clicked again', done => {
          findRearrangeButton().vm.$emit('click');
          wrapper.vm.$nextTick(() => {
            expect(findRearrangeButton().attributes('pressed')).toBeFalsy();
            expect(findEnabledDraggables().length).toBe(0);
            done();
          });
        });
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });
  });

  // https://gitlab.com/gitlab-org/gitlab-ce/issues/66922
  // eslint-disable-next-line jasmine/no-disabled-tests
  xdescribe('link to chart', () => {
    let wrapper;
    const currentDashboard = 'TEST_DASHBOARD';
    localVue.use(GlToast);
    const link = () => wrapper.find('.js-chart-link');
    const clipboardText = () => link().element.dataset.clipboardText;

    beforeEach(done => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      wrapper = shallowMount(DashboardComponent, {
        localVue,
        sync: false,
        attachToDocument: true,
        propsData: { ...propsData, hasMetrics: true, currentDashboard },
        store,
      });

      setTimeout(done);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('adds a copy button to the dropdown', () => {
      expect(link().text()).toContain('Generate link to chart');
    });

    it('contains a link to the dashboard', () => {
      expect(clipboardText()).toContain(`dashboard=${currentDashboard}`);
      expect(clipboardText()).toContain(`group=`);
      expect(clipboardText()).toContain(`title=`);
      expect(clipboardText()).toContain(`y_label=`);
    });

    it('undefined parameter is stripped', done => {
      wrapper.setProps({ currentDashboard: undefined });

      wrapper.vm.$nextTick(() => {
        expect(clipboardText()).not.toContain(`dashboard=`);
        expect(clipboardText()).toContain(`y_label=`);
        done();
      });
    });

    it('null parameter is stripped', done => {
      wrapper.setProps({ currentDashboard: null });

      wrapper.vm.$nextTick(() => {
        expect(clipboardText()).not.toContain(`dashboard=`);
        expect(clipboardText()).toContain(`y_label=`);
        done();
      });
    });

    it('creates a toast when clicked', () => {
      spyOn(wrapper.vm.$toast, 'show').and.stub();

      link().vm.$emit('click');

      expect(wrapper.vm.$toast.show).toHaveBeenCalled();
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
      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
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

  describe('external dashboard link', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
          externalDashboardUrl: '/mockUrl',
        },
        store,
      });
    });

    it('shows the link', done => {
      setTimeout(() => {
        expect(component.$el.querySelector('.js-external-dashboard-link').innerText).toContain(
          'View full dashboard',
        );
        done();
      });
    });
  });

  describe('Dashboard dropdown', () => {
    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);

      component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
        },
        store,
      });

      component.$store.dispatch('monitoringDashboard/setFeatureFlags', {
        prometheusEndpoint: false,
      });

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS}`,
        environmentData,
      );

      component.$store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        singleGroupResponse,
      );

      component.$store.commit(
        `monitoringDashboard/${types.SET_ALL_DASHBOARDS}`,
        dashboardGitResponse,
      );
    });

    it('shows the dashboard dropdown', done => {
      setTimeout(() => {
        const dashboardDropdown = component.$el.querySelector('.js-dashboards-dropdown');

        expect(dashboardDropdown).not.toEqual(null);
        done();
      });
    });
  });

  describe('when downloading metrics data as CSV', () => {
    beforeEach(() => {
      component = new DashboardComponent({
        propsData: {
          ...propsData,
        },
        store,
      });
      store.commit(
        `monitoringDashboard/${types.RECEIVE_METRICS_DATA_SUCCESS}`,
        MonitoringMock.data,
      );
      [mockGraphData] = component.$store.state.monitoringDashboard.groups[0].metrics;
    });

    describe('csvText', () => {
      it('converts metrics data from json to csv', () => {
        const header = `timestamp,${mockGraphData.y_label}`;
        const data = mockGraphData.queries[0].result[0].values;
        const firstRow = `${data[0][0]},${data[0][1]}`;

        expect(component.csvText(mockGraphData)).toMatch(`^${header}\r\n${firstRow}`);
      });
    });

    describe('downloadCsv', () => {
      it('produces a link with a Blob', () => {
        expect(component.downloadCsv(mockGraphData)).toContain(`blob:`);
      });
    });
  });
});
