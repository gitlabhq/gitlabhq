import MergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import mockData from '../mock_data';

describe('MergeRequestStore', () => {
  describe('setData', () => {
    let store;

    beforeEach(() => {
      store = new MergeRequestStore(mockData);
    });

    it('should set hasSHAChanged when the diff SHA changes', () => {
      store.setData({ ...mockData, diff_head_sha: 'a-different-string' });
      expect(store.hasSHAChanged).toBe(true);
    });

    it('should not set hasSHAChanged when other data changes', () => {
      store.setData({ ...mockData, work_in_progress: !mockData.work_in_progress });
      expect(store.hasSHAChanged).toBe(false);
    });

    it('sets isMerged to true for merged state', () => {
      store.setData({ ...mockData, state: 'merged' });

      expect(store.isMerged).toBe(true);
    });

    it('sets isMerged to false for readyToMerge state', () => {
      store.setData({ ...mockData, state: 'readyToMerge' });

      expect(store.isMerged).toBe(false);
    });
  });
});
