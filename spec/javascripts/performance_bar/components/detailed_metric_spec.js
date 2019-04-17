import Vue from 'vue';
import detailedMetric from '~/performance_bar/components/detailed_metric.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('detailedMetric', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('when the current request has no details', () => {
    beforeEach(() => {
      vm = mountComponent(Vue.extend(detailedMetric), {
        currentRequest: {},
        metric: 'gitaly',
        header: 'Gitaly calls',
        details: 'details',
        keys: ['feature', 'request'],
      });
    });

    it('does not render the element', () => {
      expect(vm.$el.innerHTML).toEqual(undefined);
    });
  });

  describe('when the current request has details', () => {
    const requestDetails = [
      { duration: '100', feature: 'find_commit', request: 'abcdef', backtrace: ['hello', 'world'] },
      { duration: '23', feature: 'rebase_in_progress', request: '', backtrace: ['world', 'hello'] },
    ];

    beforeEach(() => {
      vm = mountComponent(Vue.extend(detailedMetric), {
        currentRequest: {
          details: {
            gitaly: {
              duration: '123ms',
              calls: '456',
              details: requestDetails,
            },
          },
        },
        metric: 'gitaly',
        header: 'Gitaly calls',
        details: 'details',
        keys: ['feature', 'request'],
      });
    });

    it('diplays details', () => {
      expect(vm.$el.innerText.replace(/\s+/g, ' ')).toContain('123ms / 456');
    });

    it('adds a modal with a table of the details', () => {
      vm.$el
        .querySelectorAll('.performance-bar-modal td:nth-child(1)')
        .forEach((duration, index) => {
          expect(duration.innerText).toContain(requestDetails[index].duration);
        });

      vm.$el
        .querySelectorAll('.performance-bar-modal td:nth-child(2)')
        .forEach((feature, index) => {
          expect(feature.innerText).toContain(requestDetails[index].feature);
        });

      vm.$el
        .querySelectorAll('.performance-bar-modal td:nth-child(2)')
        .forEach((request, index) => {
          expect(request.innerText).toContain(requestDetails[index].request);
        });

      expect(vm.$el.querySelector('.text-expander.js-toggle-button')).not.toBeNull();

      vm.$el.querySelectorAll('.performance-bar-modal td:nth-child(2)').forEach(request => {
        expect(request.innerText).toContain('world');
      });
    });

    it('displays the metric name', () => {
      expect(vm.$el.innerText).toContain('gitaly');
    });
  });
});
