import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { timeWindows, timeWindowsKeyNames } from '~/monitoring/constants';
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
  customMetricsAvailable: false,
  customMetricsPath: '',
  validateQueryPath: '',
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

    window.gon = {
      ...window.gon,
      ee: false,
      features: {
        grafanaDashboardLink: true,
      },
    };

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
        propsData: { ...propsData, showTimeWindowDropdown: false },
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
        propsData: { ...propsData, hasMetrics: true, showTimeWindowDropdown: false },
      });

      Vue.nextTick(() => {
        expect(component.state).toEqual('loading');
        done();
      });
    });

    it('hides the legend when showLegend is false', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showLegend: false,
          showTimeWindowDropdown: false,
        },
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
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
        },
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
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
        },
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
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
        },
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

    it('renders the environments dropdown with a single active element', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
        },
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

    it('hides the dropdown', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          environmentsEndpoint: '',
          showTimeWindowDropdown: false,
        },
      });

      Vue.nextTick(() => {
        const dropdownIsActiveElement = component.$el.querySelectorAll('.environments');

        expect(dropdownIsActiveElement.length).toEqual(0);
        done();
      });
    });

    it('does not show the time window dropdown when the feature flag is not set', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
        },
      });

      setTimeout(() => {
        const timeWindowDropdown = component.$el.querySelector('.js-time-window-dropdown');

        expect(timeWindowDropdown).toBeNull();

        done();
      });
    });

    it('renders the time window dropdown with a set of options', done => {
      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: true,
        },
      });
      const numberOfTimeWindows = Object.keys(timeWindows).length;

      setTimeout(() => {
        const timeWindowDropdown = component.$el.querySelector('.js-time-window-dropdown');
        const timeWindowDropdownEls = component.$el.querySelectorAll(
          '.js-time-window-dropdown .dropdown-item',
        );

        expect(timeWindowDropdown).not.toBeNull();
        expect(timeWindowDropdownEls.length).toEqual(numberOfTimeWindows);

        done();
      });
    });

    it('shows a specific time window selected from the url params', done => {
      spyOnDependency(Dashboard, 'getParameterValues').and.returnValue(['thirtyMinutes']);

      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showTimeWindowDropdown: true },
      });

      setTimeout(() => {
        const selectedTimeWindow = component.$el.querySelector(
          '.js-time-window-dropdown [active="true"]',
        );

        expect(selectedTimeWindow.textContent.trim()).toEqual('30 minutes');
        done();
      });
    });

    it('defaults to the eight hours time window for non valid url parameters', done => {
      spyOnDependency(Dashboard, 'getParameterValues').and.returnValue([
        '<script>alert("XSS")</script>',
      ]);

      const component = new DashboardComponent({
        el: document.querySelector('.prometheus-graphs'),
        propsData: { ...propsData, hasMetrics: true, showTimeWindowDropdown: true },
      });

      Vue.nextTick(() => {
        expect(component.selectedTimeWindowKey).toEqual(timeWindowsKeyNames.eightHours);

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
        propsData: {
          ...propsData,
          hasMetrics: true,
          showPanels: false,
          showTimeWindowDropdown: false,
        },
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
    let component;

    beforeEach(() => {
      mock.onGet(mockApiEndpoint).reply(200, metricsGroupsAPIResponse);
    });

    afterEach(() => {
      component.$destroy();
    });

    describe('with feature flag enabled', () => {
      beforeEach(() => {
        component = new DashboardComponent({
          el: document.querySelector('.prometheus-graphs'),
          propsData: {
            ...propsData,
            hasMetrics: true,
            showPanels: false,
            showTimeWindowDropdown: false,
            externalDashboardPath: '/mockPath',
          },
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

    describe('without feature flage enabled', () => {
      beforeEach(() => {
        window.gon.features.grafanaDashboardLink = false;
        component = new DashboardComponent({
          el: document.querySelector('.prometheus-graphs'),
          propsData: {
            ...propsData,
            hasMetrics: true,
            showPanels: false,
            showTimeWindowDropdown: false,
            externalDashboardPath: '',
          },
        });
      });

      it('does not show the link', done => {
        setTimeout(() => {
          expect(component.$el.querySelector('.js-external-dashboard-link')).toBe(null);
          done();
        });
      });
    });
  });
});
