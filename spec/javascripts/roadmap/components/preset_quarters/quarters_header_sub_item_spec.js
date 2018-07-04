import Vue from 'vue';

import QuartersHeaderSubItemComponent from 'ee/roadmap/components/preset_quarters/quarters_header_sub_item.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeQuarters } from '../../mock_data';

const createComponent = ({
  currentDate = mockTimeframeQuarters[0].range[1],
  timeframeItem = mockTimeframeQuarters[0],
}) => {
  const Component = Vue.extend(QuartersHeaderSubItemComponent);

  return mountComponent(Component, {
    currentDate,
    timeframeItem,
  });
};

describe('QuartersHeaderSubItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('headerSubItems', () => {
      it('returns array of dates containing Months from timeframeItem', () => {
        vm = createComponent({});
        expect(Array.isArray(vm.headerSubItems)).toBe(true);
        vm.headerSubItems.forEach(subItem => {
          expect(subItem instanceof Date).toBe(true);
        });
      });
    });

    describe('hasToday', () => {
      it('returns true when current quarter is same as timeframe quarter', () => {
        vm = createComponent({});
        expect(vm.hasToday).toBe(true);
      });

      it('returns false when current quarter month is different from timeframe quarter', () => {
        vm = createComponent({
          currentDate: new Date(2017, 10, 1), // Nov 1, 2017
          timeframeItem: mockTimeframeQuarters[1], // 2018 Apr May Jun
        });
        expect(vm.hasToday).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('getSubItemValueClass', () => {
      it('returns string containing `label-dark` when provided subItem is greater than current date', () => {
        vm = createComponent({
          currentDate: new Date(2018, 0, 1), // Jan 1, 2018
        });
        const subItem = new Date(2018, 1, 15); // Feb 15, 2018
        expect(vm.getSubItemValueClass(subItem)).toBe('label-dark');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `item-sublabel`', () => {
      expect(vm.$el.classList.contains('item-sublabel')).toBe(true);
    });

    it('renders sub item element with class `sublabel-value`', () => {
      expect(vm.$el.querySelector('.sublabel-value')).not.toBeNull();
    });
  });
});
