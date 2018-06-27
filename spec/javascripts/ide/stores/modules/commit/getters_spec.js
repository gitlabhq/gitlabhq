import commitState from '~/ide/stores/modules/commit/state';
import * as consts from '~/ide/stores/modules/commit/constants';
import * as getters from '~/ide/stores/modules/commit/getters';

describe('IDE commit module getters', () => {
  let state;

  beforeEach(() => {
    state = commitState();
  });

  describe('discardDraftButtonDisabled', () => {
    it('returns true when commitMessage is empty', () => {
      expect(getters.discardDraftButtonDisabled(state)).toBeTruthy();
    });

    it('returns false when commitMessage is not empty & loading is false', () => {
      state.commitMessage = 'test';
      state.submitCommitLoading = false;

      expect(getters.discardDraftButtonDisabled(state)).toBeFalsy();
    });

    it('returns true when commitMessage is not empty & loading is true', () => {
      state.commitMessage = 'test';
      state.submitCommitLoading = true;

      expect(getters.discardDraftButtonDisabled(state)).toBeTruthy();
    });
  });

  describe('commitButtonDisabled', () => {
    const localGetters = {
      discardDraftButtonDisabled: false,
    };
    const rootState = {
      stagedFiles: ['a'],
    };

    it('returns false when discardDraftButtonDisabled is false & stagedFiles is not empty', () => {
      expect(
        getters.commitButtonDisabled(state, localGetters, rootState),
      ).toBeFalsy();
    });

    it('returns true when discardDraftButtonDisabled is false & stagedFiles is empty', () => {
      rootState.stagedFiles.length = 0;

      expect(
        getters.commitButtonDisabled(state, localGetters, rootState),
      ).toBeTruthy();
    });

    it('returns true when discardDraftButtonDisabled is true', () => {
      localGetters.discardDraftButtonDisabled = true;

      expect(
        getters.commitButtonDisabled(state, localGetters, rootState),
      ).toBeTruthy();
    });

    it('returns true when discardDraftButtonDisabled is false & changedFiles is not empty', () => {
      localGetters.discardDraftButtonDisabled = false;
      rootState.stagedFiles.length = 0;

      expect(
        getters.commitButtonDisabled(state, localGetters, rootState),
      ).toBeTruthy();
    });
  });

  describe('newBranchName', () => {
    it('includes username, currentBranchId, patch & random number', () => {
      gon.current_username = 'username';

      const branch = getters.newBranchName(state, null, {
        currentBranchId: 'testing',
      });

      expect(branch).toMatch(/username-testing-patch-\d{5}$/);
    });
  });

  describe('branchName', () => {
    const rootState = {
      currentBranchId: 'master',
    };
    const localGetters = {
      newBranchName: 'newBranchName',
    };

    beforeEach(() => {
      Object.assign(state, {
        newBranchName: 'state-newBranchName',
      });
    });

    it('defualts to currentBranchId', () => {
      expect(getters.branchName(state, null, rootState)).toBe('master');
    });

    ['COMMIT_TO_NEW_BRANCH', 'COMMIT_TO_NEW_BRANCH_MR'].forEach(type => {
      describe(type, () => {
        beforeEach(() => {
          Object.assign(state, {
            commitAction: consts[type],
          });
        });

        it('uses newBranchName when not empty', () => {
          expect(getters.branchName(state, localGetters, rootState)).toBe(
            'state-newBranchName',
          );
        });

        it('uses getters newBranchName when state newBranchName is empty', () => {
          Object.assign(state, {
            newBranchName: '',
          });

          expect(getters.branchName(state, localGetters, rootState)).toBe(
            'newBranchName',
          );
        });
      });
    });
  });
});
