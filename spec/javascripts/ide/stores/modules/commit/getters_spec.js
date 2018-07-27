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
          expect(getters.branchName(state, localGetters, rootState)).toBe('state-newBranchName');
        });

        it('uses getters newBranchName when state newBranchName is empty', () => {
          Object.assign(state, {
            newBranchName: '',
          });

          expect(getters.branchName(state, localGetters, rootState)).toBe('newBranchName');
        });
      });
    });
  });

  describe('preBuiltCommitMessage', () => {
    let rootState = {};

    beforeEach(() => {
      rootState.changedFiles = [];
      rootState.stagedFiles = [];
    });

    afterEach(() => {
      rootState = {};
    });

    it('returns commitMessage when set', () => {
      state.commitMessage = 'test commit message';

      expect(getters.preBuiltCommitMessage(state, null, rootState)).toBe('test commit message');
    });

    ['changedFiles', 'stagedFiles'].forEach(key => {
      it('returns commitMessage with updated file', () => {
        rootState[key].push({
          path: 'test-file',
        });

        expect(getters.preBuiltCommitMessage(state, null, rootState)).toBe('Update test-file');
      });

      it('returns commitMessage with updated files', () => {
        rootState[key].push(
          {
            path: 'test-file',
          },
          {
            path: 'index.js',
          },
        );

        expect(getters.preBuiltCommitMessage(state, null, rootState)).toBe(
          'Update test-file, index.js files',
        );
      });

      it('returns commitMessage with deleted files', () => {
        rootState[key].push(
          {
            path: 'test-file',
            deleted: true,
          },
          {
            path: 'index.js',
          },
        );

        expect(getters.preBuiltCommitMessage(state, null, rootState)).toBe(
          'Update index.js\nDeleted test-file',
        );
      });
    });
  });
});
