import Vue from 'vue';

import MonthsHeaderItemComponent from 'ee/roadmap/components/preset_months/months_header_item.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeMonths, mockShellWidth, mockItemWidth } from '../../mock_data';

const mockTimeframeIndex = 0;

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframeMonths[mockTimeframeIndex],
  timeframe = mockTimeframeMonths,
  shellWidth = mockShellWidth,
  itemWidth = mockItemWidth,
}) => {
  const Component = Vue.extend(MonthsHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
    shellWidth,
    itemWidth,
  });
};

describe('MonthsHeaderItemComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('data', () => {
    it('returns default data props', () => {
      vm = createComponent({});
      const currentDate = new Date();
      expect(vm.currentDate.getDate()).toBe(currentDate.getDate());
      expect(vm.currentYear).toBe(currentDate.getFullYear());
      expect(vm.currentMonth).toBe(currentDate.getMonth());
    });
  });

  describe('computed', () => {
    describe('itemStyles', () => {
      it('returns style object for container element based on value of `itemWidth` prop', () => {
        vm = createComponent({});
        expect(vm.itemStyles.width).toBe('180px');
      });
    });

    describe('timelineHeaderLabel', () => {
      it('returns string containing Year and Month for current timeline header item', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderLabel).toBe('2017 Dec');
      });

      it('returns string containing only Month for current timeline header item when previous header contained Year', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 1,
          timeframeItem: mockTimeframeMonths[mockTimeframeIndex + 1],
        });
        expect(vm.timelineHeaderLabel).toBe('2018 Jan');
      });
    });

    describe('timelineHeaderClass', () => {
      it('returns empty string when timeframeItem year or month is less than current year or month', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderClass).toBe('');
      });

      it('returns string containing `label-dark label-bold` when current year and month is same as timeframeItem year and month', () => {
        vm = createComponent({
          timeframeItem: new Date(),
        });
        expect(vm.timelineHeaderClass).toBe('label-dark label-bold');
      });

      it('returns string containing `label-dark` when current year and month is less than timeframeItem year and month', () => {
        const timeframeIndex = 2;
        const timeframeItem = new Date(
          mockTimeframeMonths[timeframeIndex].getFullYear(),
          mockTimeframeMonths[timeframeIndex].getMonth() + 2,
          1,
        );
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        vm.currentYear = mockTimeframeMonths[timeframeIndex].getFullYear();
        vm.currentMonth = mockTimeframeMonths[timeframeIndex].getMonth() + 1;
        expect(vm.timelineHeaderClass).toBe('label-dark');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      vm = createComponent({});
    });

    it('renders component container element with class `timeline-header-item`', () => {
      expect(vm.$el.classList.contains('timeline-header-item')).toBeTruthy();
    });

    it('renders item label element class `item-label` and value as `timelineHeaderLabel`', () => {
      const itemLabelEl = vm.$el.querySelector('.item-label');
      expect(itemLabelEl).not.toBeNull();
      expect(itemLabelEl.innerText.trim()).toBe('2017 Dec');
    });
  });
});
