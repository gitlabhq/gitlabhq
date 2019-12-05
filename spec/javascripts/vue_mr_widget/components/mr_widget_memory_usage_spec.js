import Vue from 'vue';
import MemoryUsage from '~/vue_merge_request_widget/components/deployment/memory_usage.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

const url = '/root/acets-review-apps/environments/15/deployments/1/metrics';
const monitoringUrl = '/root/acets-review-apps/environments/15/metrics';

const metricsMockData = {
  success: true,
  metrics: {
    memory_before: [
      {
        metric: {},
        value: [1495785220.607, '9572875.906976745'],
      },
    ],
    memory_after: [
      {
        metric: {},
        value: [1495787020.607, '4485853.130206379'],
      },
    ],
    memory_values: [
      {
        metric: {},
        values: [[1493716685, '4.30859375']],
      },
    ],
  },
  last_update: '2017-05-02T12:34:49.628Z',
  deployment_time: 1493718485,
};

const createComponent = () => {
  const Component = Vue.extend(MemoryUsage);

  return new Component({
    el: document.createElement('div'),
    propsData: {
      metricsUrl: url,
      metricsMonitoringUrl: monitoringUrl,
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
  loadingMetrics: 'Loading deployment statistics',
  hasMetrics: 'Memory  usage is  unchanged  at 0MB',
  loadFailed: 'Failed to load deployment statistics',
  metricsUnavailable: 'Deployment statistics are not available currently',
};

describe('MemoryUsage', () => {
  let vm;
  let el;

  beforeEach(() => {
    vm = createComponent();
    el = vm.$el;
  });

  describe('data', () => {
    it('should have default data', () => {
      const data = MemoryUsage.data();

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

  describe('computed', () => {
    describe('memoryChangeMessage', () => {
      it('should contain "increased" if memoryFrom value is less than memoryTo value', () => {
        vm.memoryFrom = 4.28;
        vm.memoryTo = 9.13;

        expect(vm.memoryChangeMessage.indexOf('increased')).not.toEqual('-1');
      });

      it('should contain "decreased" if memoryFrom value is less than memoryTo value', () => {
        vm.memoryFrom = 9.13;
        vm.memoryTo = 4.28;

        expect(vm.memoryChangeMessage.indexOf('decreased')).not.toEqual('-1');
      });

      it('should contain "unchanged" if memoryFrom value equal to memoryTo value', () => {
        vm.memoryFrom = 1;
        vm.memoryTo = 1;

        expect(vm.memoryChangeMessage.indexOf('unchanged')).not.toEqual('-1');
      });
    });
  });

  describe('methods', () => {
    const { metrics, deployment_time } = metricsMockData;

    describe('getMegabytes', () => {
      it('should return Megabytes from provided Bytes value', () => {
        const memoryInBytes = '9572875.906976745';

        expect(vm.getMegabytes(memoryInBytes)).toEqual('9.13');
      });
    });

    describe('computeGraphData', () => {
      it('should populate sparkline graph', () => {
        vm.computeGraphData(metrics, deployment_time);
        const { hasMetrics, memoryMetrics, deploymentTime, memoryFrom, memoryTo } = vm;

        expect(hasMetrics).toBeTruthy();
        expect(memoryMetrics.length).toBeGreaterThan(0);
        expect(deploymentTime).toEqual(deployment_time);
        expect(memoryFrom).toEqual('9.13');
        expect(memoryTo).toEqual('4.28');
      });
    });

    describe('loadMetrics', () => {
      const returnServicePromise = () =>
        new Promise(resolve => {
          resolve({
            data: metricsMockData,
          });
        });

      it('should load metrics data using MRWidgetService', done => {
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

    it('should show loading metrics message while metrics are being loaded', done => {
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

    it('should show deployment memory usage when metrics are loaded', done => {
      vm.loadingMetrics = false;
      vm.hasMetrics = true;
      vm.loadFailed = false;
      vm.memoryMetrics = metricsMockData.metrics.memory_values[0].values;

      Vue.nextTick(() => {
        expect(el.querySelector('.memory-graph-container')).toBeDefined();
        expect(el.querySelector('.js-usage-info').innerText).toContain(messages.hasMetrics);
        done();
      });
    });

    it('should show failure message when metrics loading failed', done => {
      vm.loadingMetrics = false;
      vm.hasMetrics = false;
      vm.loadFailed = true;

      Vue.nextTick(() => {
        expect(el.querySelector('.js-usage-info.usage-info-failed')).toBeDefined();

        expect(el.querySelector('.js-usage-info').innerText).toContain(messages.loadFailed);
        done();
      });
    });

    it('should show metrics unavailable message when metrics loading failed', done => {
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
