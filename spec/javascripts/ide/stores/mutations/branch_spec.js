import mutations from 'ee/ide/stores/mutations/branch';
import state from 'ee/ide/stores/state';

describe('Multi-file store branch mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_CURRENT_BRANCH', () => {
    it('sets currentBranch', () => {
      mutations.SET_CURRENT_BRANCH(localState, 'master');

      expect(localState.currentBranchId).toBe('master');
    });
  });
});
