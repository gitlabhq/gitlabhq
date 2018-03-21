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

    it('does not display details', () => {
      expect(vm.$el.innerText).not.toContain('/');
    });

    it('does not display the modal', () => {
      expect(vm.$el.querySelector('.performance-bar-modal')).toBeNull();
    });

    it('displays the metric name', () => {
      expect(vm.$el.innerText).toContain('gitaly');
    });
  });

  describe('when the current request has details', () => {
    const requestDetails = [
      { duration: '100', feature: 'find_commit', request: 'abcdef' },
      { duration: '23', feature: 'rebase_in_progress', request: '' },
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
        .querySelectorAll('.performance-bar-modal td strong')
        .forEach((duration, index) => {
          expect(duration.innerText).toContain(requestDetails[index].duration);
        });

      vm.$el
        .querySelectorAll('.performance-bar-modal td:nth-child(2)')
        .forEach((feature, index) => {
          expect(feature.innerText).toContain(requestDetails[index].feature);
        });

      vm.$el
        .querySelectorAll('.performance-bar-modal td:nth-child(3)')
        .forEach((request, index) => {
          expect(request.innerText).toContain(requestDetails[index].request);
        });
    });

    it('displays the metric name', () => {
      expect(vm.$el.innerText).toContain('gitaly');
    });
  });
});
