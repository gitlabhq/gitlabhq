import Vue from 'vue';

import stackedProgressBarComponent from '~/vue_shared/components/stacked_progress_bar.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

const createComponent = (config) => {
  const Component = Vue.extend(stackedProgressBarComponent);
  const defaultConfig = Object.assign({}, {
    successLabel: 'Synced',
    failureLabel: 'Failed',
    neutralLabel: 'Out of sync',
    successCount: 10,
    failureCount: 5,
    totalCount: 20,
  }, config);

  return mountComponent(Component, defaultConfig);
};

describe('StackedProgressBarComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('neutralCount', () => {
      it('returns neutralCount based on totalCount, successCount and failureCount', () => {
        expect(vm.neutralCount).toBe(5); // 20 - 10 - 5
      });
    });
  });

  describe('methods', () => {
    describe('getPercent', () => {
      it('returns percentage from provided count based on `totalCount`', () => {
        expect(vm.getPercent(10)).toBe(50);
      });
    });

    describe('barStyle', () => {
      it('returns style string based on percentage provided', () => {
        expect(vm.barStyle(50)).toBe('width: 50%;');
      });
    });

    describe('getTooltip', () => {
      it('returns label string based on label and count provided', () => {
        expect(vm.getTooltip('Synced', 10)).toBe('Synced: 10');
      });
    });
  });

  describe('template', () => {
    it('renders container element', () => {
      expect(vm.$el.classList.contains('stacked-progress-bar')).toBeTruthy();
    });

    it('renders empty state when count is unavailable', () => {
      const vmX = createComponent({ totalCount: 0, successCount: 0, failureCount: 0 });
      expect(vmX.$el.querySelectorAll('.status-unavailable').length).not.toBe(0);
      vmX.$destroy();
    });

    it('renders bar elements when count is available', () => {
      expect(vm.$el.querySelectorAll('.status-green').length).not.toBe(0);
      expect(vm.$el.querySelectorAll('.status-neutral').length).not.toBe(0);
      expect(vm.$el.querySelectorAll('.status-red').length).not.toBe(0);
    });
  });
});
