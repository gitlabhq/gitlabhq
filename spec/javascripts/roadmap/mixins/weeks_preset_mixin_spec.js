import Vue from 'vue';

import EpicItemTimelineComponent from 'ee/roadmap/components/epic_item_timeline.vue';
import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockTimeframeWeeks, mockEpic, mockShellWidth, mockItemWidth } from '../mock_data';

const createComponent = ({
  presetType = PRESET_TYPES.WEEKS,
  timeframe = mockTimeframeWeeks,
  timeframeItem = mockTimeframeWeeks[0],
  epic = mockEpic,
  shellWidth = mockShellWidth,
  itemWidth = mockItemWidth,
}) => {
  const Component = Vue.extend(EpicItemTimelineComponent);

  return mountComponent(Component, {
    presetType,
    timeframe,
    timeframeItem,
    epic,
    shellWidth,
    itemWidth,
  });
};

describe('WeeksPresetMixin', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('hasStartDateForWeek', () => {
      it('returns true when Epic.startDate falls within timeframeItem', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, { startDate: mockTimeframeWeeks[1] }),
          timeframeItem: mockTimeframeWeeks[1],
        });
        expect(vm.hasStartDateForWeek()).toBe(true);
      });

      it('returns false when Epic.startDate does not fall within timeframeItem', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, { startDate: mockTimeframeWeeks[0] }),
          timeframeItem: mockTimeframeWeeks[1],
        });
        expect(vm.hasStartDateForWeek()).toBe(false);
      });
    });

    describe('getLastDayOfWeek', () => {
      it('returns date object set to last day of the week from provided timeframeItem', () => {
        vm = createComponent({});
        const lastDayOfWeek = vm.getLastDayOfWeek(mockTimeframeWeeks[0]);
        expect(lastDayOfWeek.getDate()).toBe(30);
        expect(lastDayOfWeek.getMonth()).toBe(11);
        expect(lastDayOfWeek.getFullYear()).toBe(2017);
      });
    });

    describe('isTimeframeUnderEndDateForWeek', () => {
      beforeEach(() => {
        vm = createComponent({});
      });

      it('returns true if provided timeframeItem is under epicEndDate', () => {
        const timeframeItem = new Date(2018, 0, 7); // Jan 7, 2018
        const epicEndDate = new Date(2018, 0, 3); // Jan 3, 2018
        expect(vm.isTimeframeUnderEndDateForWeek(timeframeItem, epicEndDate)).toBe(true);
      });

      it('returns false if provided timeframeItem is NOT under epicEndDate', () => {
        const timeframeItem = new Date(2018, 0, 7); // Jan 7, 2018
        const epicEndDate = new Date(2018, 0, 15); // Jan 15, 2018
        expect(vm.isTimeframeUnderEndDateForWeek(timeframeItem, epicEndDate)).toBe(false);
      });
    });

    describe('getBarWidthForSingleWeek', () => {
      it('returns calculated bar width based on provided cellWidth and day of week', () => {
        vm = createComponent({});
        expect(Math.floor(vm.getBarWidthForSingleWeek(300, 1))).toBe(42); // 10% size
        expect(Math.floor(vm.getBarWidthForSingleWeek(300, 3))).toBe(128); // 50% size
        expect(vm.getBarWidthForSingleWeek(300, 7)).toBe(300); // Full size
      });
    });

    describe('getTimelineBarEndOffsetHalfForWeek', () => {
      it('returns timeline bar end offset for Weeks view', () => {
        vm = createComponent({});
        expect(vm.getTimelineBarEndOffsetHalfForWeek()).toBe(28);
      });
    });

    describe('getTimelineBarStartOffsetForWeeks', () => {
      it('returns empty string when Epic startDate is out of range', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, { startDateOutOfRange: true }),
        });
        expect(vm.getTimelineBarStartOffsetForWeeks()).toBe('');
      });

      it('returns empty string when Epic startDate is undefined and endDate is out of range', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            startDateUndefined: true,
            endDateOutOfRange: true,
          }),
        });
        expect(vm.getTimelineBarStartOffsetForWeeks()).toBe('');
      });

      it('return `left: 0;` when Epic startDate is first day of the week', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            startDate: mockTimeframeWeeks[0],
          }),
        });
        expect(vm.getTimelineBarStartOffsetForWeeks()).toBe('left: 0;');
      });

      it('returns `right: 8px;` when Epic startDate is in last timeframe month and endDate is out of range', () => {
        const startDate = new Date(mockTimeframeWeeks[mockTimeframeWeeks.length - 1].getTime());
        startDate.setDate(startDate.getDate() + 1);
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            startDate,
            endDateOutOfRange: true,
          }),
        });
        expect(vm.getTimelineBarStartOffsetForWeeks()).toBe('right: 8px;');
      });

      it('returns proportional `left` value based on Epic startDate and days in the month', () => {
        vm = createComponent({
          epic: Object.assign({}, mockEpic, {
            startDate: new Date(2018, 0, 15),
          }),
        });
        expect(vm.getTimelineBarStartOffsetForWeeks()).toContain('left: 60');
      });
    });

    describe('getTimelineBarWidthForWeeks', () => {
      it('returns calculated width value based on Epic.startDate and Epic.endDate', () => {
        vm = createComponent({
          shellWidth: 2000,
          timeframeItem: mockTimeframeWeeks[0],
          epic: Object.assign({}, mockEpic, {
            startDate: new Date(2018, 0, 1), // Jan 1, 2018
            endDate: new Date(2018, 1, 2), // Feb 2, 2018
          }),
        });
        expect(Math.floor(vm.getTimelineBarWidthForWeeks())).toBe(1600);
      });
    });
  });
});
