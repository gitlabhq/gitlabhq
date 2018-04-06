import MergeRequestStore from 'ee/vue_merge_request_widget/stores/mr_widget_store';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
import mockData, {
  headIssues,
  baseIssues,
  parsedBaseIssues,
  parsedHeadIssues,
} from '../mock_data';

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

    describe('isNothingToMergeState', () => {
      it('returns true when nothingToMerge', () => {
        store.state = stateKey.nothingToMerge;
        expect(store.isNothingToMergeState).toEqual(true);
      });

      it('returns false when not nothingToMerge', () => {
        store.state = 'state';
        expect(store.isNothingToMergeState).toEqual(false);
      });
    });
  });

  describe('compareCodeclimateMetrics', () => {
    beforeEach(() => {
      store.compareCodeclimateMetrics(headIssues, baseIssues, 'headPath', 'basePath');
    });

    it('should return the new issues', () => {
      expect(store.codeclimateMetrics.newIssues[0]).toEqual(parsedHeadIssues[0]);
    });

    it('should return the resolved issues', () => {
      expect(store.codeclimateMetrics.resolvedIssues[0]).toEqual(parsedBaseIssues[0]);
    });
  });

  describe('parseCodeclimateMetrics', () => {
    it('should parse the received issues', () => {
      const codequality = MergeRequestStore.parseCodeclimateMetrics(baseIssues, 'path')[0];
      expect(codequality.name).toEqual(baseIssues[0].check_name);
      expect(codequality.path).toEqual(baseIssues[0].location.path);
      expect(codequality.line).toEqual(baseIssues[0].location.lines.begin);
    });
  });

  describe('isNothingToMergeState', () => {
    it('returns true when nothingToMerge', () => {
      store.state = stateKey.nothingToMerge;
      expect(store.isNothingToMergeState).toEqual(true);
    });

    it('returns false when not nothingToMerge', () => {
      store.state = 'state';
      expect(store.isNothingToMergeState).toEqual(false);
    });
  });
});
