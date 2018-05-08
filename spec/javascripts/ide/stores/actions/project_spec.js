import {
  refreshLastCommitData,
  getLastCommitPipeline,
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
        [{
          type: 'SET_BRANCH_COMMIT',
          payload: {
            projectId: 'abcproject',
            branchId: 'master',
            commit: { id: '123' },
          },
        }], // mutations
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

  describe('getLastCommitPipeline', () => {
    beforeEach(() => {
      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'master';
      store.state.projects.abcproject = {
        id: 4,
        branches: {
          master: {
            commit: {
              id: 'abc123def456ghi789jkl',
              title: 'example',
            },
          },
        },
      };
      spyOn(service, 'getPipelinesForProject').and.returnValue(
        Promise.resolve({
          data: [
            { id: '1', ref: 'master', sha: 'lkj987ihg654fed321cba', status: 'failed' },
            { id: '2', ref: 'master', sha: 'abc123def456ghi789jkl', status: 'passed' },
          ],
        }),
      );
    });

    it('calls the service', done => {
      store
        .dispatch('getLastCommitPipeline', {
          projectId: store.state.currentProjectId,
          projectIdNumber: store.state.projects[store.state.currentProjectId].id,
          branchId: store.state.currentBranchId,
        })
        .then(() => {
          expect(service.getPipelinesForProject).toHaveBeenCalledWith(4);

          done();
        })
        .catch(done.fail);
    });

    it('commits correct pipeline', done => {
      testAction(
        getLastCommitPipeline,
        {
          projectId: 'abcproject',
          projectIdNumber: store.state.projects.abcproject.id,
          branchId: 'master',
        },
        store.state,
        [{
          type: 'SET_LAST_COMMIT_PIPELINE',
          payload: {
            projectId: 'abcproject',
            branchId: 'master',
            pipeline: {
              id: '2',
              ref: 'master',
              sha: 'abc123def456ghi789jkl',
              status: 'passed',
            },
          },
        }], // mutations
        [], // action
        done,
      );
    });

    it('doesn\'t commit anything if no pipeline exists for last commit', done => {
      store.state.projects.abcproject.branches.master.commit.id = 'nonexistanthash';

      testAction(
        getLastCommitPipeline,
        {
          projectId: 'abcproject',
          projectIdNumber: store.state.projects.abcproject.id,
          branchId: 'master',
        },
        store.state,
        [], // mutations
        [], // action
        done,
      );
    });
  });
});
