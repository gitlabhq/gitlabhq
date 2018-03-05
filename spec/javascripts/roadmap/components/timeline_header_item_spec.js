import Vue from 'vue';

import timelineHeaderItemComponent from 'ee/roadmap/components/timeline_header_item.vue';
import { TIMELINE_CELL_MIN_WIDTH } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframe, mockShellWidth } from '../mock_data';

const mockTimeframeIndex = 0;

const createComponent = ({
  timeframeIndex = mockTimeframeIndex,
  timeframeItem = mockTimeframe[mockTimeframeIndex],
  timeframe = mockTimeframe,
  shellWidth = mockShellWidth,
}) => {
  const Component = Vue.extend(timelineHeaderItemComponent);

  return mountComponent(Component, {
    timeframeIndex,
    timeframeItem,
    timeframe,
    shellWidth,
  });
};

describe('TimelineHeaderItemComponent', () => {
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
    describe('thStyles', () => {
      it('returns style string for th element based on shellWidth, timeframe length and Epic details cell width', () => {
        vm = createComponent({});
        expect(vm.thStyles).toBe('min-width: 280px;');
      });

      it('returns style string for th element with minimum permissible width when calculated width is lower defined minimum width', () => {
        vm = createComponent({ shellWidth: 1000 });
        expect(vm.thStyles).toBe(`min-width: ${TIMELINE_CELL_MIN_WIDTH}px;`);
      });
    });

    describe('timelineHeaderLabel', () => {
      it('returns string containing Year and Month for current timeline header item', () => {
        vm = createComponent({});
        expect(vm.timelineHeaderLabel).toBe('2017 Nov');
      });

      it('returns string containing only Month for current timeline header item when previous header contained Year', () => {
        vm = createComponent({
          timeframeIndex: mockTimeframeIndex + 1,
          timeframeItem: mockTimeframe[mockTimeframeIndex + 1],
        });
        expect(vm.timelineHeaderLabel).toBe('Dec');
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
          mockTimeframe[timeframeIndex].getFullYear(),
          mockTimeframe[timeframeIndex].getMonth() + 2,
          1,
        );
        vm = createComponent({
          timeframeIndex,
          timeframeItem,
        });

        vm.currentYear = mockTimeframe[timeframeIndex].getFullYear();
        vm.currentMonth = mockTimeframe[timeframeIndex].getMonth() + 1;
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
      expect(itemLabelEl.innerText.trim()).toBe('2017 Nov');
    });
  });
});
