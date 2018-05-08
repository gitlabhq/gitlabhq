import {
  refreshLastCommitData,
} from '~/ide/stores/actions';
import store from '~/ide/stores';
import service from '~/ide/services';
import { resetStore } from '../../helpers';
import testAction from '../../../helpers/vuex_action_helper';

describe('IDE store project actions', () => {
  beforeEach(() => {
    store.state.projects.abcproject = {};
  });

  afterEach(() => {
    resetStore(store);
  });

  describe('refreshLastCommitData', () => {
    beforeEach(() => {
      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'master';
      store.state.projects.abcproject = {
        branches: {
          master: {
            commit: null,
          },
        },
      };
    });

    it('calls the service', done => {
      spyOn(service, 'getBranchData').and.returnValue(
        Promise.resolve({
          data: {
            commit: { id: '123' },
          },
        }),
      );

      store
        .dispatch('refreshLastCommitData', {
          projectId: store.state.currentProjectId,
          branchId: store.state.currentBranchId,
        })
        .then(() => {
          expect(service.getBranchData).toHaveBeenCalledWith('abcproject', 'master');

          done();
        })
        .catch(done.fail);
    });

    it('commits getBranchData', done => {
      testAction(
        refreshLastCommitData,
        {},
        {},
        [{
          type: 'SET_BRANCH_COMMIT',
          payload: {
            projectId: 'abcproject',
            branchId: 'master',
            commit: { id: '123' },
          },
        }], // mutations
        [], // action
        done,
      );
    });
  });
});
