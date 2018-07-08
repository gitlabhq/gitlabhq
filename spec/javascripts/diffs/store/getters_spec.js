import * as getters from '~/diffs/store/getters';
import state from '~/diffs/store/modules/diff_state';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';

describe('DiffsStoreGetters', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('isParallelView', () => {
    it('should return true if view set to parallel view', () => {
      localState.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(getters.isParallelView(localState)).toEqual(true);
    });

    it('should return false if view not to parallel view', () => {
      localState.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(getters.isParallelView(localState)).toEqual(false);
    });
  });

  describe('isInlineView', () => {
    it('should return true if view set to inline view', () => {
      localState.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(getters.isInlineView(localState)).toEqual(true);
    });

    it('should return false if view not to inline view', () => {
      localState.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(getters.isInlineView(localState)).toEqual(false);
    });
  });

  describe('areAllFilesCollapsed', () => {
    it('returns true when all files are collapsed', () => {
      localState.diffFiles = [{ collapsed: true }, { collapsed: true }];
      expect(getters.areAllFilesCollapsed(localState)).toEqual(true);
    });

    it('returns false when at least one file is not collapsed', () => {
      localState.diffFiles = [{ collapsed: false }, { collapsed: true }];
      expect(getters.areAllFilesCollapsed(localState)).toEqual(false);
    });
  });

  describe('commitId', () => {
    it('returns commit id when is set', () => {
      const commitID = '800f7a91';
      localState.commit = {
        id: commitID,
      };

      expect(getters.commitId(localState)).toEqual(commitID);
    });

    it('returns null when no commit is set', () => {
      expect(getters.commitId(localState)).toEqual(null);
    });
  });
});
