import commitState from '~/ide/stores/modules/commit/state';
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

  });

  describe('newBranchName', () => {
    it('includes username, currentBranchId, patch & random number', () => {
      gon.current_username = 'username';

      const branch = getters.newBranchName(state, null, { currentBranchId: 'testing' });

      expect(branch).toMatch(/username-testing-patch-\d{5}$/);
    });
  });

  describe('branchName', () => {

  });
});
