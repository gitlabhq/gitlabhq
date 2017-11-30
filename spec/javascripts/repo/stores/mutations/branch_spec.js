import mutations from '~/repo/stores/mutations/branch';
import state from '~/repo/stores/state';

describe('Multi-file store branch mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_CURRENT_BRANCH', () => {
    it('sets currentBranch', () => {
      mutations.SET_CURRENT_BRANCH(localState, 'master');

      expect(localState.currentBranch).toBe('master');
    });
  });
});
