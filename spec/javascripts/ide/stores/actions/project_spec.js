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

  describe('getCommitPipeline', () => {
    const fullPipelinesResponse = Promise.resolve({
      data: {
        count: {
          all: 2,
        },
        pipelines: [
          {
            id: '51',
            details: {
              status: {
                icon: 'status_failed',
                text: 'failed',
              },
            },
          },
          {
            id: '50',
            details: {
              status: {
                icon: 'status_passed',
                text: 'passed',
              },
            },
          },
        ],
      },
    });
    const emptyPipelinesResponse = Promise.resolve({
      data: {
        count: {
          all: 0,
        },
        pipelines: [],
      },
    });

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
    });

    it('calls the service', done => {
      spyOn(service, 'commitPipelines').and.returnValue(fullPipelinesResponse);

      store
        .dispatch('getCommitPipeline', {
          projectId: store.state.currentProjectId,
          branchId: store.state.currentBranchId,
          commitSha:
            store.state.projects[store.state.currentProjectId].branches[store.state.currentBranchId]
              .commit.id,
        })
        .then(() => {
          expect(service.commitPipelines).toHaveBeenCalledWith(
            'abcproject',
            'abc123def456ghi789jkl',
          );

          done();
        })
        .catch(done.fail);
    });

    it('commits correct pipeline', done => {
      spyOn(service, 'commitPipelines').and.returnValue(fullPipelinesResponse);

      testAction(
        getCommitPipeline,
        {
          projectId: 'abcproject',
          projectIdNumber: store.state.projects.abcproject.id,
          branchId: 'master',
        },
        store.state,
        [
          {
            type: 'SET_LAST_COMMIT_PIPELINE',
            payload: {
              projectId: 'abcproject',
              branchId: 'master',
              pipeline: {
                id: '51',
                details: {
                  status: {
                    icon: 'status_failed',
                    text: 'failed',
                  },
                },
              },
            },
          },
        ], // mutations
        [], // action
        done,
      );
    });

    it("doesn't commit anything if no pipeline exists for last commit", done => {
      spyOn(service, 'commitPipelines').and.returnValue(emptyPipelinesResponse);

      testAction(
        getCommitPipeline,
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
