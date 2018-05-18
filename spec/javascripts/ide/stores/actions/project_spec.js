import { refreshLastCommitData, getCommitPipeline } from '~/ide/stores/actions';
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
        id: 4,
        branches: {
          master: {
            commit: null,
          },
        },
      };
      spyOn(service, 'getBranchData').and.returnValue(
        Promise.resolve({
          data: {
            commit: { id: '123' },
          },
        }),
      );
    });

    it('calls the service', done => {
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
        {
          projectId: store.state.currentProjectId,
          branchId: store.state.currentBranchId,
        },
        store.state,
        [
          {
            type: 'SET_BRANCH_COMMIT',
            payload: {
              projectId: 'abcproject',
              branchId: 'master',
              commit: { id: '123' },
            },
          },
        ], // mutations
        [
          {
            type: 'getLastCommitPipeline',
            payload: {
              projectId: 'abcproject',
              projectIdNumber: store.state.projects.abcproject.id,
              branchId: 'master',
            },
          },
        ], // action
        done,
      );
    });
  });
