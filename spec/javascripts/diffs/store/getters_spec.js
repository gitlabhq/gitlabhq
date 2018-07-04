import getters from '~/diffs/store/getters';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';

describe('DiffsStoreGetters', () => {
  describe('isParallelView', () => {
    it('should return true if view set to parallel view', () => {
      expect(getters.isParallelView({ diffViewType: PARALLEL_DIFF_VIEW_TYPE })).toBeTruthy();
    });

    it('should return false if view not to parallel view', () => {
      expect(getters.isParallelView({ diffViewType: 'foo' })).toBeFalsy();
    });
  });

  describe('isInlineView', () => {
    it('should return true if view set to inline view', () => {
      expect(getters.isInlineView({ diffViewType: INLINE_DIFF_VIEW_TYPE })).toBeTruthy();
    });

    it('should return false if view not to inline view', () => {
      expect(getters.isInlineView({ diffViewType: PARALLEL_DIFF_VIEW_TYPE })).toBeFalsy();
    });
  });
});
