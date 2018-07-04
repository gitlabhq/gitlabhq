import RoadmapStore from 'ee/roadmap/store/roadmap_store';
import { PRESET_TYPES } from 'ee/roadmap/constants';
import { mockGroupId, mockTimeframeMonths, rawEpics } from '../mock_data';

describe('RoadmapStore', () => {
  let store;

  beforeEach(() => {
    store = new RoadmapStore(mockGroupId, mockTimeframeMonths, PRESET_TYPES.MONTHS);
  });

  describe('constructor', () => {
    it('initializes default state', () => {
      expect(store.state).toBeDefined();
      expect(Array.isArray(store.state.epics)).toBe(true);
      expect(store.state.currentGroupId).toBe(mockGroupId);
      expect(store.state.timeframe).toBe(mockTimeframeMonths);
      expect(store.presetType).toBe(PRESET_TYPES.MONTHS);
      expect(store.timeframeStartDate).toBeDefined();
      expect(store.timeframeEndDate).toBeDefined();
    });
  });

  describe('setEpics', () => {
    it('sets Epics list to state', () => {
      store.setEpics(rawEpics);
      expect(store.getEpics().length).toBe(rawEpics.length);
    });
  });

  describe('getCurrentGroupId', () => {
    it('gets currentGroupId from store state', () => {
      expect(store.getCurrentGroupId()).toBe(mockGroupId);
    });
  });

  describe('getTimeframe', () => {
    it('gets timeframe from store state', () => {
      expect(store.getTimeframe()).toBe(mockTimeframeMonths);
    });
  });

  describe('formatEpicDetails', () => {
    const rawEpic = rawEpics[0];

    it('returns formatted Epic object from raw Epic object', () => {
      const epic = RoadmapStore.formatEpicDetails(rawEpic);
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.name).toBe(rawEpic.name);
      expect(epic.groupId).toBe(rawEpic.group_id);
      expect(epic.groupName).toBe(rawEpic.group_name);
    });

    it('returns formatted Epic object with startDateUndefined and proxy date set when start date is not available', () => {
      const rawEpicWithoutSD = Object.assign({}, rawEpic, {
        start_date: null,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicWithoutSD,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.startDateUndefined).toBe(true);
      expect(epic.startDate.getTime()).toBe(store.timeframeStartDate.getTime());
    });

    it('returns formatted Epic object with endDateUndefined and proxy date set when end date is not available', () => {
      const rawEpicWithoutED = Object.assign({}, rawEpic, {
        end_date: null,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicWithoutED,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.endDateUndefined).toBe(true);
      expect(epic.endDate.getTime()).toBe(store.timeframeEndDate.getTime());
    });

    it('returns formatted Epic object with startDateOutOfRange, proxy date and cached original start date set when start date is out of timeframe range', () => {
      const rawStartDate = '2017-1-1';
      const rawEpicSDOut = Object.assign({}, rawEpic, {
        start_date: rawStartDate,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicSDOut,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.startDateOutOfRange).toBe(true);
      expect(epic.startDate.getTime()).toBe(store.timeframeStartDate.getTime());
      expect(epic.originalStartDate.getTime()).toBe(new Date(rawStartDate).getTime());
    });

    it('returns formatted Epic object with endDateOutOfRange, proxy date and cached original end date set when end date is out of timeframe range', () => {
      const rawEndDate = '2019-1-1';
      const rawEpicEDOut = Object.assign({}, rawEpic, {
        end_date: rawEndDate,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicEDOut,
        store.timeframeStartDate,
        store.timeframeEndDate,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.endDateOutOfRange).toBe(true);
      expect(epic.endDate.getTime()).toBe(store.timeframeEndDate.getTime());
      expect(epic.originalEndDate.getTime()).toBe(new Date(rawEndDate).getTime());
    });
  });
});
