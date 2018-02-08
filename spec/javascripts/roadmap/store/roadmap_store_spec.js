import RoadmapStore from 'ee/roadmap/store/roadmap_store';
import { mockGroupId, mockTimeframe, rawEpics } from '../mock_data';

describe('RoadmapStore', () => {
  let store;

  beforeEach(() => {
    store = new RoadmapStore(mockGroupId, mockTimeframe);
  });

  describe('constructor', () => {
    it('initializes default state', () => {
      expect(store.state).toBeDefined();
      expect(Array.isArray(store.state.epics)).toBe(true);
      expect(store.state.currentGroupId).toBe(mockGroupId);
      expect(store.state.timeframe).toBe(mockTimeframe);
      expect(store.firstTimeframeItem).toBe(store.state.timeframe[0]);
      expect(store.lastTimeframeItem).toBe(store.state.timeframe[store.state.timeframe.length - 1]);
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
      expect(store.getTimeframe()).toBe(mockTimeframe);
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
        store.firstTimeframeItem,
        store.lastTimeframeItem,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.startDateUndefined).toBe(true);
      expect(epic.startDate.getTime()).toBe(store.firstTimeframeItem.getTime());
    });

    it('returns formatted Epic object with endDateUndefined and proxy date set when end date is not available', () => {
      const rawEpicWithoutED = Object.assign({}, rawEpic, {
        end_date: null,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicWithoutED,
        store.firstTimeframeItem,
        store.lastTimeframeItem,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.endDateUndefined).toBe(true);
      expect(epic.endDate.getTime()).toBe(store.lastTimeframeItem.getTime());
    });

    it('returns formatted Epic object with startDateOutOfRange, proxy date and cached original start date set when start date is out of timeframe range', () => {
      const rawStartDate = '2017-1-1';
      const rawEpicSDOut = Object.assign({}, rawEpic, {
        start_date: rawStartDate,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicSDOut,
        store.firstTimeframeItem,
        store.lastTimeframeItem,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.startDateOutOfRange).toBe(true);
      expect(epic.startDate.getTime()).toBe(store.firstTimeframeItem.getTime());
      expect(epic.originalStartDate.getTime()).toBe(new Date(rawStartDate).getTime());
    });

    it('returns formatted Epic object with endDateOutOfRange, proxy date and cached original end date set when end date is out of timeframe range', () => {
      const rawEndDate = '2019-1-1';
      const rawEpicEDOut = Object.assign({}, rawEpic, {
        end_date: rawEndDate,
      });
      const epic = RoadmapStore.formatEpicDetails(
        rawEpicEDOut,
        store.firstTimeframeItem,
        store.lastTimeframeItem,
      );
      expect(epic.id).toBe(rawEpic.id);
      expect(epic.endDateOutOfRange).toBe(true);
      expect(epic.endDate.getTime()).toBe(store.lastTimeframeItem.getTime());
      expect(epic.originalEndDate.getTime()).toBe(new Date(rawEndDate).getTime());
    });
  });
});
