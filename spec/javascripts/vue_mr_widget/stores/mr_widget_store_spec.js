import MergeRequestStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';
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

    describe('isPipelinePassing', () => {
      it('is true when the CI status is `success`', () => {
        store.setData({ ...mockData, ci_status: 'success' });
        expect(store.isPipelinePassing).toBe(true);
      });

      it('is true when the CI status is `success_with_warnings`', () => {
        store.setData({ ...mockData, ci_status: 'success_with_warnings' });
        expect(store.isPipelinePassing).toBe(true);
      });

      it('is false when the CI status is `failed`', () => {
        store.setData({ ...mockData, ci_status: 'failed' });
        expect(store.isPipelinePassing).toBe(false);
      });

      it('is false when the CI status is anything except `success`', () => {
        store.setData({ ...mockData, ci_status: 'foobarbaz' });
        expect(store.isPipelinePassing).toBe(false);
      });
    });

    describe('isPipelineSkipped', () => {
      it('should set isPipelineSkipped=true when the CI status is `skipped`', () => {
        store.setData({ ...mockData, ci_status: 'skipped' });
        expect(store.isPipelineSkipped).toBe(true);
      });

      it('should set isPipelineSkipped=false when the CI status is anything except `skipped`', () => {
        store.setData({ ...mockData, ci_status: 'foobarbaz' });
        expect(store.isPipelineSkipped).toBe(false);
      });
    });
  });

  describe('compareCodeclimateMetrics', () => {
    beforeEach(() => {
      store.compareCodeclimateMetrics(headIssues, baseIssues, 'headPath', 'basePath');
    });

    it('should return the new issues', () => {
      const parsed = MergeRequestStore.addPathToIssues(headIssues, 'headPath');
      expect(store.codeclimateMetrics.newIssues[0]).toEqual(parsed[0]);
    });

    it('should return the resolved issues', () => {
      const parsed = MergeRequestStore.addPathToIssues(baseIssues, 'basePath');
      expect(store.codeclimateMetrics.resolvedIssues[0]).toEqual(parsed[1]);
    });
  });

  describe('addPathToIssues', () => {
    it('should add urlPath key to each entry', () => {
      expect(
        MergeRequestStore.addPathToIssues(headIssues, 'path')[0].location.urlPath,
      ).toEqual(`path/${headIssues[0].location.path}#L${headIssues[0].location.lines.begin}`);
    });

    it('should return the same object whe there is no locaiton', () => {
      expect(
        MergeRequestStore.addPathToIssues([{ check_name: 'foo' }], 'path'),
      ).toEqual([{ check_name: 'foo' }]);
    });
  });
});
