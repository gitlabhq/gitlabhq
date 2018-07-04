import Vue from 'vue';

import WeeksHeaderSubItemComponent from 'ee/roadmap/components/preset_weeks/weeks_header_sub_item.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeWeeks } from '../../mock_data';

const createComponent = ({
  currentDate = mockTimeframeWeeks[0],
  timeframeItem = mockTimeframeWeeks[0],
}) => {
  const Component = Vue.extend(WeeksHeaderSubItemComponent);

  return mountComponent(Component, {
    currentDate,
    timeframeItem,
  });
};

describe('MonthsHeaderSubItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('sets prop `headerSubItems` with array of dates containing days of week from timeframeItem', () => {
      vm = createComponent({});
      expect(Array.isArray(vm.headerSubItems)).toBe(true);
      expect(vm.headerSubItems.length).toBe(7);
      vm.headerSubItems.forEach(subItem => {
        expect(subItem instanceof Date).toBe(true);
      });
    });
  });

  describe('computed', () => {
    describe('hasToday', () => {
      it('returns true when current week is same as timeframe week', () => {
        vm = createComponent({});
        expect(vm.hasToday).toBe(true);
      });

      it('returns false when current week is different from timeframe week', () => {
        vm = createComponent({
          currentDate: new Date(2017, 10, 1), // Nov 1, 2017
          timeframeItem: new Date(2018, 0, 1), // Jan 1, 2018
        });
        expect(vm.hasToday).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('getSubItemValueClass', () => {
      it('returns string containing `label-dark` when provided subItem is greater than current week day', () => {
        vm = createComponent({
          currentDate: new Date(2018, 0, 1), // Jan 1, 2018
        });
        const subItem = new Date(2018, 0, 25); // Jan 25, 2018
        expect(vm.getSubItemValueClass(subItem)).toBe('label-dark');
      });

      it('returns string containing `label-dark label-bold` when provided subItem is same as current week day', () => {
        const currentDate = new Date(2018, 0, 25);
        vm = createComponent({
          currentDate,
        });
        const subItem = currentDate;
        expect(vm.getSubItemValueClass(subItem)).toBe('label-dark label-bold');
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
