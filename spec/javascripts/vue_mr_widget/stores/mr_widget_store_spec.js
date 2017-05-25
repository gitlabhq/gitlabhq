import MergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import mockData, { headIssues, baseIssues } from '../mock_data';

describe('MergeRequestStore', () => {
  let store;

  beforeEach(() => {
    store = new MergeRequestStore(mockData);
  });

  describe('setData', () => {
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
    it('should set defaults', () => {
      expect(store.codeclimate).toEqual(mockData.codeclimate);
      expect(store.codeclimateMetrics).toEqual({
        headIssues: [],
        baseIssues: [],
        newIssues: [],
        resolvedIssues: [],
      });
    });

    it('should set the provided head metrics', () => {
      store.setCodeclimateHeadMetrics(headIssues);
      expect(store.codeclimateMetrics.headIssues).toEqual(headIssues);
    });
  });

  describe('setCodeclimateBaseMetrics', () => {
    it('should set the provided base metrics', () => {
      store.setCodeclimateBaseMetrics(baseIssues);

      expect(store.codeclimateMetrics.baseIssues).toEqual(baseIssues);
    });
  });

  describe('compareCodeclimateMetrics', () => {
    beforeEach(() => {
      store.setCodeclimateHeadMetrics(headIssues);
      store.setCodeclimateBaseMetrics(baseIssues);
      store.compareCodeclimateMetrics();
    });

    it('should return the new issues', () => {
      expect(store.codeclimateMetrics.newIssues[0]).toEqual(headIssues[0]);
    });

    it('should return the resolved issues', () => {
      expect(store.codeclimateMetrics.resolvedIssues[0]).toEqual(baseIssues[1]);
    });
  });
});
