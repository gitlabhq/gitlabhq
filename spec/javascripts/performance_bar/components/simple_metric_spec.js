import Vue from 'vue';
import simpleMetric from '~/performance_bar/components/simple_metric.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('simpleMetric', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('when the current request has no details', () => {
    beforeEach(() => {
      vm = mountComponent(Vue.extend(simpleMetric), {
        currentRequest: {},
        metric: 'gitaly',
      });
    });

    it('does not display details', () => {
      expect(vm.$el.innerText).not.toContain('/');
    });

    it('displays the metric name', () => {
      expect(vm.$el.innerText).toContain('gitaly');
    });
  });

  describe('when the current request has details', () => {
    beforeEach(() => {
      vm = mountComponent(Vue.extend(simpleMetric), {
        currentRequest: {
          details: { gitaly: { duration: '123ms', calls: '456' } },
        },
        metric: 'gitaly',
      });
    });

    it('diplays details', () => {
      expect(vm.$el.innerText.replace(/\s+/g, ' ')).toContain('123ms / 456');
    });

    it('displays the metric name', () => {
      expect(vm.$el.innerText).toContain('gitaly');
    });
  });
});
