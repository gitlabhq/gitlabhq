import mutations from '~/ide/stores/mutations/branch';
import state from '~/ide/stores/state';

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

  describe('SET_BRANCH_COMMIT', () => {
    it('sets the last commit on current project', () => {
      localState.projects = {
        Example: {
          branches: {
            master: {},
          },
        },
      };

      mutations.SET_BRANCH_COMMIT(localState, {
        projectId: 'Example',
        branchId: 'master',
        commit: {
          title: 'Example commit',
        },
      });

      expect(localState.projects.Example.branches.master.commit.title).toBe('Example commit');
    });
  });
});
