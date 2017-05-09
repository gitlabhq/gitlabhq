import Vue from 'vue';
import memoryUsageComponent from '~/vue_merge_request_widget/components/mr_widget_memory_usage';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

const url = '/root/acets-review-apps/environments/15/deployments/1/metrics';

const metricsMockData = {
  success: true,
  metrics: {
    memory_values: [
      {
        metric: {},
        values: [
          [1493716685, '4.30859375'],
        ],
      },
    ],
  },
  last_update: '2017-05-02T12:34:49.628Z',
  deployment_time: 1493718485,
};

const createComponent = () => {
  const Component = Vue.extend(memoryUsageComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: {
      metricsUrl: url,
      memoryMetrics: [],
      deploymentTime: 0,
      hasMetrics: false,
      loadFailed: false,
      loadingMetrics: true,
      backOffRequestCounter: 0,
    },
  });
};

const messages = {
  loadingMetrics: 'Loading deployment statistics.',
  hasMetrics: 'Deployment memory usage:',
  loadFailed: 'Failed to load deployment statistics.',
  metricsUnavailable: 'Deployment statistics are not available currently.',
};

describe('MemoryUsage', () => {
  let vm;
  let el;

  beforeEach(() => {
    vm = createComponent();
    el = vm.$el;
  });

  describe('props', () => {
    it('should have props with defaults', () => {
      const { metricsUrl } = memoryUsageComponent.props;
      const MetricsUrlTypeClass = metricsUrl.type;

      Vue.nextTick(() => {
        expect(new MetricsUrlTypeClass() instanceof String).toBeTruthy();
        expect(metricsUrl.required).toBeTruthy();
      });
    });
  });

  describe('data', () => {
    it('should have default data', () => {
      const data = memoryUsageComponent.data();

      expect(Array.isArray(data.memoryMetrics)).toBeTruthy();
      expect(data.memoryMetrics.length).toBe(0);

      expect(typeof data.deploymentTime).toBe('number');
      expect(data.deploymentTime).toBe(0);

      expect(typeof data.hasMetrics).toBe('boolean');
      expect(data.hasMetrics).toBeFalsy();

      expect(typeof data.loadFailed).toBe('boolean');
      expect(data.loadFailed).toBeFalsy();

      expect(typeof data.loadingMetrics).toBe('boolean');
      expect(data.loadingMetrics).toBeTruthy();

      expect(typeof data.backOffRequestCounter).toBe('number');
      expect(data.backOffRequestCounter).toBe(0);
    });
  });

  describe('methods', () => {
    const { metrics, deployment_time } = metricsMockData;

    describe('computeGraphData', () => {
      it('should populate sparkline graph', () => {
        vm.computeGraphData(metrics, deployment_time);
        const { hasMetrics, memoryMetrics, deploymentTime } = vm;

        expect(hasMetrics).toBeTruthy();
        expect(memoryMetrics.length > 0).toBeTruthy();
        expect(deploymentTime).toEqual(deployment_time);
      });
    });

    describe('loadMetrics', () => {
      const returnServicePromise = () => new Promise((resolve) => {
        resolve({
          json() {
            return metricsMockData;
          },
        });
      });

      it('should load metrics data using MRWidgetService', (done) => {
        spyOn(MRWidgetService, 'fetchMetrics').and.returnValue(returnServicePromise(true));
        spyOn(vm, 'computeGraphData');

        vm.loadMetrics();
        setTimeout(() => {
          expect(MRWidgetService.fetchMetrics).toHaveBeenCalledWith(url);
          expect(vm.computeGraphData).toHaveBeenCalledWith(metrics, deployment_time);
          done();
        }, 333);
      });
    });
  });

  describe('template', () => {
    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-memory-usage')).toBeTruthy();
      expect(el.querySelector('.js-usage-info')).toBeDefined();
    });

    it('should show loading metrics message while metrics are being loaded', (done) => {
      vm.loadingMetrics = true;
      vm.hasMetrics = false;
      vm.loadFailed = false;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-usage-info.usage-info-loading')).toBeDefined();
        expect(el.querySelector('.js-usage-info .usage-info-load-spinner')).toBeDefined();
        expect(el.querySelector('.js-usage-info').innerText).toContain(messages.loadingMetrics);
        done();
      });
    });

    it('should show deployment memory usage when metrics are loaded', (done) => {
      vm.loadingMetrics = false;
      vm.hasMetrics = true;
      vm.loadFailed = false;

      Vue.nextTick(() => {
        expect(el.querySelector('.memory-graph-container')).toBeDefined();
        expect(el.querySelector('.js-usage-info').innerText).toContain(messages.hasMetrics);
        done();
      });
    });

    it('should show failure message when metrics loading failed', (done) => {
      vm.loadingMetrics = false;
      vm.hasMetrics = false;
      vm.loadFailed = true;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-usage-info.usage-info-failed')).toBeDefined();
        expect(el.querySelector('.js-usage-info').innerText).toContain(messages.loadFailed);
        done();
      });
    });

    it('should show metrics unavailable message when metrics loading failed', (done) => {
      vm.loadingMetrics = false;
      vm.hasMetrics = false;
      vm.loadFailed = false;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-usage-info.usage-info-unavailable')).toBeDefined();
        expect(el.querySelector('.js-usage-info').innerText).toContain(messages.metricsUnavailable);
        done();
      });
    });
  });
});
