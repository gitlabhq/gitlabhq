import Vue from 'vue';

import epicItemDetailsComponent from 'ee/roadmap/components/epic_item_details.vue';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockGroupId, mockEpic } from '../mock_data';

const createComponent = (epic = mockEpic, currentGroupId = mockGroupId) => {
  const Component = Vue.extend(epicItemDetailsComponent);

  return mountComponent(Component, {
    epic,
    currentGroupId,
  });
};

describe('EpicItemDetailsComponent', () => {
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('isEpicGroupDifferent', () => {
      it('returns true when Epic.groupId is different from currentGroupId', () => {
        const mockEpicItem = Object.assign({}, mockEpic, { groupId: 1 });
        vm = createComponent(mockEpicItem, 2);

        expect(vm.isEpicGroupDifferent).toBe(true);
      });

      it('returns false when Epic.groupId is same as currentGroupId', () => {
        const mockEpicItem = Object.assign({}, mockEpic, { groupId: 1 });
        vm = createComponent(mockEpicItem, 1);

        expect(vm.isEpicGroupDifferent).toBe(false);
      });
    });

    describe('startDate', () => {
      it('returns Epic.startDate when start date is within range', () => {
        vm = createComponent(mockEpic);

        expect(vm.startDate).toBe(mockEpic.startDate);
      });

      it('returns Epic.originalStartDate when start date is out of range', () => {
        const mockStartDate = new Date(2018, 0, 1);
        const mockEpicItem = Object.assign({}, mockEpic, {
          startDateOutOfRange: true,
          originalStartDate: mockStartDate,
        });
        vm = createComponent(mockEpicItem);

        expect(vm.startDate).toBe(mockStartDate);
      });
    });

    describe('endDate', () => {
      it('returns Epic.endDate when end date is within range', () => {
        vm = createComponent(mockEpic);

        expect(vm.endDate).toBe(mockEpic.endDate);
      });

      it('returns Epic.originalEndDate when end date is out of range', () => {
        const mockEndDate = new Date(2018, 0, 1);
        const mockEpicItem = Object.assign({}, mockEpic, {
          endDateOutOfRange: true,
          originalEndDate: mockEndDate,
        });
        vm = createComponent(mockEpicItem);

        expect(vm.endDate).toBe(mockEndDate);
      });
    });

    describe('timeframeString', () => {
      it('returns timeframe string correctly when both start and end dates are defined', () => {
        vm = createComponent(mockEpic);

        expect(vm.timeframeString).toBe('Jul 10, 2017 &ndash; Jun 2, 2018');
      });

      it('returns timeframe string correctly when only start date is defined', () => {
        const mockEpicItem = Object.assign({}, mockEpic, {
          endDateUndefined: true,
        });
        vm = createComponent(mockEpicItem);

        expect(vm.timeframeString).toBe('From Jul 10, 2017');
      });

      it('returns timeframe string correctly when only end date is defined', () => {
        const mockEpicItem = Object.assign({}, mockEpic, {
          startDateUndefined: true,
        });
        vm = createComponent(mockEpicItem);

        expect(vm.timeframeString).toBe('Until Jun 2, 2018');
      });

      it('returns timeframe string with hidden year for start date when both start and end dates are from same year', () => {
        const mockEpicItem = Object.assign({}, mockEpic, {
          startDate: new Date(2018, 0, 1),
          endDate: new Date(2018, 3, 1),
        });
        vm = createComponent(mockEpicItem);

        expect(vm.timeframeString).toBe('Jan 1 &ndash; Apr 1, 2018');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `epic-details-cell`', () => {
      vm = createComponent();

      expect(vm.$el.classList.contains('epic-details-cell')).toBe(true);
    });

    it('renders Epic title correctly', () => {
      vm = createComponent();
      const epicTitleEl = vm.$el.querySelector('.epic-title .epic-url');

      expect(epicTitleEl).not.toBeNull();
      expect(epicTitleEl.getAttribute('href')).toBe(mockEpic.webUrl);
      expect(epicTitleEl.innerText.trim()).toBe(mockEpic.title);
    });

    it('renders Epic group name and tooltip', () => {
      const mockEpicItem = Object.assign({}, mockEpic, {
        groupId: 1,
        groupName: 'Bar',
        groupFullName: 'Foo / Bar',
      });
      vm = createComponent(mockEpicItem, 2);
      const epicGroupNameEl = vm.$el.querySelector('.epic-group-timeframe .epic-group');

      expect(epicGroupNameEl).not.toBeNull();
      expect(epicGroupNameEl.innerText.trim()).toContain(mockEpicItem.groupName);
      expect(epicGroupNameEl.dataset.originalTitle).toBe(mockEpicItem.groupFullName);
    });

    it('renders Epic timeframe', () => {
      vm = createComponent();
      const epicTimeframeEl = vm.$el.querySelector('.epic-group-timeframe .epic-timeframe');

      expect(epicTimeframeEl).not.toBeNull();
      expect(epicTimeframeEl.innerText.trim()).toBe('Jul 10, 2017 – Jun 2, 2018');
    });
  });
});
