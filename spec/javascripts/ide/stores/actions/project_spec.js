import Visibility from 'visibilityjs';
import MockAdapter from 'axios-mock-adapter';
import { refreshLastCommitData, pollSuccessCallBack } from '~/ide/stores/actions';
import store from '~/ide/stores';
import service from '~/ide/services';
import axios from '~/lib/utils/axios_utils';
import { fullPipelinesResponse } from '../../mock_data';
import { resetStore } from '../../helpers';
import testAction from '../../../helpers/vuex_action_helper';

describe('IDE store project actions', () => {
  const setProjectState = () => {
    store.state.currentProjectId = 'abc/def';
    store.state.currentBranchId = 'master';
    store.state.projects['abc/def'] = {
      id: 4,
      path_with_namespace: 'abc/def',
      branches: {
        master: {
          commit: {
            id: 'abc123def456ghi789jkl',
            title: 'example',
          },
        },
      },
    };
  };

  beforeEach(() => {
    store.state.projects['abc/def'] = {};
  });

  afterEach(() => {
    resetStore(store);
  });

  describe('refreshLastCommitData', () => {
    beforeEach(() => {
      store.state.currentProjectId = 'abc/def';
      store.state.currentBranchId = 'master';
      store.state.projects['abc/def'] = {
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
          expect(service.getBranchData).toHaveBeenCalledWith('abc/def', 'master');

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
              projectId: 'abc/def',
              branchId: 'master',
              commit: { id: '123' },
            },
          },
        ], // mutations
        [
          {
            type: 'getLastCommitPipeline',
            payload: {
              projectId: 'abc/def',
              projectIdNumber: store.state.projects['abc/def'].id,
              branchId: 'master',
            },
          },
        ], // action
        done,
      );
    });
  });

  describe('pipelinePoll', () => {
    let mock;

    beforeEach(() => {
      setProjectState();
      jasmine.clock().install();
      mock = new MockAdapter(axios);
      mock
        .onGet('/abc/def/commit/abc123def456ghi789jkl/pipelines')
        .reply(200, { data: { foo: 'bar' } }, { 'poll-interval': '10000' });
    });

    afterEach(() => {
      jasmine.clock().uninstall();
      mock.restore();
      store.dispatch('stopPipelinePolling');
    });

    it('calls service periodically', done => {
      spyOn(axios, 'get').and.callThrough();
      spyOn(Visibility, 'hidden').and.returnValue(false);

      store
        .dispatch('pipelinePoll')
        .then(() => {
          jasmine.clock().tick(1000);

          expect(axios.get).toHaveBeenCalled();
          expect(axios.get.calls.count()).toBe(1);
        })
        .then(() => new Promise(resolve => requestAnimationFrame(resolve)))
        .then(() => {
          jasmine.clock().tick(10000);
          expect(axios.get.calls.count()).toBe(2);
        })
        .then(() => new Promise(resolve => requestAnimationFrame(resolve)))
        .then(() => {
          jasmine.clock().tick(10000);
          expect(axios.get.calls.count()).toBe(3);
        })
        .then(() => new Promise(resolve => requestAnimationFrame(resolve)))
        .then(() => {
          jasmine.clock().tick(10000);
          expect(axios.get.calls.count()).toBe(4);
        })

        .then(done)
        .catch(done.fail);
    });
  });

  describe('pollSuccessCallBack', () => {
    beforeEach(() => {
      setProjectState();
    });

    it('commits correct pipeline', done => {
      testAction(
        pollSuccessCallBack,
        fullPipelinesResponse,
        store.state,
        [
          {
            type: 'SET_LAST_COMMIT_PIPELINE',
            payload: {
              projectId: 'abc/def',
              branchId: 'master',
              pipeline: {
                id: '50',
                commit: {
                  id: 'abc123def456ghi789jkl',
                },
                details: {
                  status: {
                    icon: 'status_passed',
                    text: 'passed',
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
  });
});
