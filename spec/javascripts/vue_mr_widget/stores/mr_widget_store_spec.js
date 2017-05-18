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
  });

  describe('setCodeclimateHeadMetrics', () => {
    it('should set the provided head metrics', () => {

    });
  });

  describe('setCodeclimateBaseMetrics', () => {
    it('should set the provided base metrics', () => {

    });
  });

  describe('compareCodeclimateMetrics', () => {
    it('should return the new issues', () => {

    });

    it('should return the resolved issues', () => {

    });
  });
});
