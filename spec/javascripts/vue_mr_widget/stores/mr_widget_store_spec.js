import MergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { stateKey } from '~/vue_merge_request_widget/stores/state_maps';
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
});
