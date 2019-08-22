import commitState from '~/ide/stores/modules/commit/state';
import * as getters from '~/ide/stores/modules/commit/getters';
import consts from '~/ide/stores/modules/commit/constants';

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

  describe('placeholderBranchName', () => {
    it('includes username, currentBranchId, patch & random number', () => {
      gon.current_username = 'username';

      const branch = getters.placeholderBranchName(state, null, {
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
      placeholderBranchName: 'placeholder-branch-name',
    };

    beforeEach(() => {
      Object.assign(state, {
        newBranchName: 'state-newBranchName',
      });
    });

    it('defaults to currentBranchId when not committing to a new branch', () => {
      localGetters.isCreatingNewBranch = false;

      expect(getters.branchName(state, localGetters, rootState)).toBe('master');
    });

    describe('commit to a new branch', () => {
      beforeEach(() => {
        localGetters.isCreatingNewBranch = true;
      });

      it('uses newBranchName when not empty', () => {
        const newBranchName = 'nonempty-branch-name';
        Object.assign(state, {
          newBranchName,
        });

        expect(getters.branchName(state, localGetters, rootState)).toBe(newBranchName);
      });

      it('uses placeholderBranchName when state newBranchName is empty', () => {
        Object.assign(state, {
          newBranchName: '',
        });

        expect(getters.branchName(state, localGetters, rootState)).toBe('placeholder-branch-name');
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

  describe('isCreatingNewBranch', () => {
    it('returns false if NOT creating a new branch', () => {
      state.commitAction = consts.COMMIT_TO_CURRENT_BRANCH;

      expect(getters.isCreatingNewBranch(state)).toBeFalsy();
    });

    it('returns true if creating a new branch', () => {
      state.commitAction = consts.COMMIT_TO_NEW_BRANCH;

      expect(getters.isCreatingNewBranch(state)).toBeTruthy();
    });
  });

  describe('shouldHideNewMrOption', () => {
    let localGetters = {};
    let rootGetters = {};

    beforeEach(() => {
      localGetters = {
        isCreatingNewBranch: null,
      };
      rootGetters = {
        isOnDefaultBranch: null,
        hasMergeRequest: null,
        canPushToBranch: null,
      };
    });

    describe('NO existing MR for the branch', () => {
      beforeEach(() => {
        rootGetters.hasMergeRequest = false;
      });

      it('should never hide "New MR" option', () => {
        expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();
      });
    });

    describe('existing MR for the branch', () => {
      beforeEach(() => {
        rootGetters.hasMergeRequest = true;
      });

      it('should NOT hide "New MR" option if user can NOT push to the current branch', () => {
        rootGetters.canPushToBranch = false;

        expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();
      });

      it('should hide "New MR" option if user can push to the current branch', () => {
        rootGetters.canPushToBranch = true;

        expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeTruthy();
      });
    });

    describe('user can NOT push the branch', () => {
      beforeEach(() => {
        rootGetters.canPushToBranch = false;
      });

      it('should never hide "New MR" option', () => {
        expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();
      });
    });

    describe('user can push to the branch', () => {
      beforeEach(() => {
        rootGetters.canPushToBranch = true;
      });

      it('should NOT hide "New MR" option if there is NO existing MR for the current branch', () => {
        rootGetters.hasMergeRequest = false;

        expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();
      });

      it('should hide "New MR" option if there is existing MR for the current branch', () => {
        rootGetters.hasMergeRequest = true;

        expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeTruthy();
      });
    });

    describe('default branch', () => {
      beforeEach(() => {
        rootGetters.isOnDefaultBranch = true;
      });

      describe('committing to the same branch', () => {
        beforeEach(() => {
          localGetters.isCreatingNewBranch = false;
          rootGetters.canPushToBranch = true;
        });

        it('should hide "New MR" when there is an existing MR', () => {
          rootGetters.hasMergeRequest = true;

          expect(
            getters.shouldHideNewMrOption(state, localGetters, null, rootGetters),
          ).toBeTruthy();
        });

        it('should hide "New MR" when there is no existing MR', () => {
          rootGetters.hasMergeRequest = false;

          expect(
            getters.shouldHideNewMrOption(state, localGetters, null, rootGetters),
          ).toBeTruthy();
        });
      });

      describe('creating a new branch', () => {
        beforeEach(() => {
          localGetters.isCreatingNewBranch = true;
        });

        it('should NOT hide "New MR" option no matter existence of an MR or write access', () => {
          rootGetters.hasMergeRequest = false;
          rootGetters.canPushToBranch = true;

          expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();

          rootGetters.hasMergeRequest = true;
          rootGetters.canPushToBranch = true;

          expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();

          rootGetters.hasMergeRequest = false;
          rootGetters.canPushToBranch = false;

          expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();
        });
      });
    });

    it('should never hide "New MR" option when creating a new branch', () => {
      localGetters.isCreatingNewBranch = true;

      rootGetters.isOnDefaultBranch = false;
      rootGetters.hasMergeRequest = true;
      rootGetters.canPushToBranch = true;

      expect(getters.shouldHideNewMrOption(state, localGetters, null, rootGetters)).toBeFalsy();
    });
  });
});
