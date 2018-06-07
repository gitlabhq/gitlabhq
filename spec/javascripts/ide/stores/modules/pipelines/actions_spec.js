import Visibility from 'visibilityjs';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import actions, {
  requestLatestPipeline,
  receiveLatestPipelineError,
  receiveLatestPipelineSuccess,
  fetchLatestPipeline,
  stopPipelinePolling,
  clearEtagPoll,
  requestJobs,
  receiveJobsError,
  receiveJobsSuccess,
  fetchJobs,
  toggleStageCollapsed,
  setDetailJob,
  requestJobTrace,
  receiveJobTraceError,
  receiveJobTraceSuccess,
  fetchJobTrace,
} from '~/ide/stores/modules/pipelines/actions';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import { rightSidebarViews } from '~/ide/constants';
import testAction from '../../../../helpers/vuex_action_helper';
import { pipelines, jobs } from '../../../mock_data';

describe('IDE pipelines actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);

    gon.api_version = 'v4';
    mockedState.currentProjectId = 'test/project';
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestLatestPipeline', () => {
    it('commits request', done => {
      testAction(
        requestLatestPipeline,
        null,
        mockedState,
        [{ type: types.REQUEST_LATEST_PIPELINE }],
        [],
        done,
      );
    });
  });

  describe('receiveLatestPipelineError', () => {
    it('commits error', done => {
      testAction(
        receiveLatestPipelineError,
        null,
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_ERROR }],
        [{ type: 'stopPipelinePolling' }],
        done,
      );
    });

    it('creates flash message', () => {
      const flashSpy = spyOnDependency(actions, 'flash');

      receiveLatestPipelineError({ commit() {}, dispatch() {} });

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveLatestPipelineSuccess', () => {
    const rootGetters = {
      lastCommit: { id: '123' },
    };
    let commit;

    beforeEach(() => {
      commit = jasmine.createSpy('commit');
    });

    it('commits pipeline', () => {
      receiveLatestPipelineSuccess({ rootGetters, commit }, { pipelines });

      expect(commit.calls.argsFor(0)).toEqual([
        types.RECEIVE_LASTEST_PIPELINE_SUCCESS,
        pipelines[0],
      ]);
    });

    it('commits false when there are no pipelines', () => {
      receiveLatestPipelineSuccess({ rootGetters, commit }, { pipelines: [] });

      expect(commit.calls.argsFor(0)).toEqual([types.RECEIVE_LASTEST_PIPELINE_SUCCESS, false]);
    });
  });

  describe('fetchLatestPipeline', () => {
    beforeEach(() => {
      jasmine.clock().install();
    });

    afterEach(() => {
      jasmine.clock().uninstall();
      stopPipelinePolling();
      clearEtagPoll();
    });

    describe('success', () => {
      beforeEach(() => {
        mock
          .onGet('/abc/def/commit/abc123def456ghi789jkl/pipelines')
          .reply(200, { data: { foo: 'bar' } }, { 'poll-interval': '10000' });
      });

      it('dispatches request', done => {
        spyOn(axios, 'get').and.callThrough();
        spyOn(Visibility, 'hidden').and.returnValue(false);

        const dispatch = jasmine.createSpy('dispatch');
        const rootGetters = {
          lastCommit: { id: 'abc123def456ghi789jkl' },
          currentProject: { path_with_namespace: 'abc/def' },
        };

        fetchLatestPipeline({ dispatch, rootGetters });

        expect(dispatch.calls.argsFor(0)).toEqual(['requestLatestPipeline']);

        jasmine.clock().tick(1000);

        new Promise(resolve => requestAnimationFrame(resolve))
          .then(() => {
            expect(axios.get).toHaveBeenCalled();
            expect(axios.get.calls.count()).toBe(1);

            expect(dispatch.calls.argsFor(1)).toEqual([
              'receiveLatestPipelineSuccess',
              jasmine.anything(),
            ]);

            jasmine.clock().tick(10000);
          })
          .then(() => new Promise(resolve => requestAnimationFrame(resolve)))
          .then(() => {
            expect(axios.get).toHaveBeenCalled();
            expect(axios.get.calls.count()).toBe(2);

            expect(dispatch.calls.argsFor(2)).toEqual([
              'receiveLatestPipelineSuccess',
              jasmine.anything(),
            ]);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet('/abc/def/commit/abc123def456ghi789jkl/pipelines').reply(500);
      });

      it('dispatches error', done => {
        const dispatch = jasmine.createSpy('dispatch');
        const rootGetters = {
          lastCommit: { id: 'abc123def456ghi789jkl' },
          currentProject: { path_with_namespace: 'abc/def' },
        };

        fetchLatestPipeline({ dispatch, rootGetters });

        jasmine.clock().tick(1500);

        new Promise(resolve => requestAnimationFrame(resolve))
          .then(() => {
            expect(dispatch.calls.argsFor(1)).toEqual(['receiveLatestPipelineError']);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('requestJobs', () => {
    it('commits request', done => {
      testAction(requestJobs, 1, mockedState, [{ type: types.REQUEST_JOBS, payload: 1 }], [], done);
    });
  });

  describe('receiveJobsError', () => {
    it('commits error', done => {
      testAction(
        receiveJobsError,
        1,
        mockedState,
        [{ type: types.RECEIVE_JOBS_ERROR, payload: 1 }],
        [],
        done,
      );
    });

    it('creates flash message', () => {
      const flashSpy = spyOnDependency(actions, 'flash');

      receiveJobsError({ commit() {} }, 1);

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveJobsSuccess', () => {
    it('commits data', done => {
      testAction(
        receiveJobsSuccess,
        { id: 1, data: jobs },
        mockedState,
        [{ type: types.RECEIVE_JOBS_SUCCESS, payload: { id: 1, data: jobs } }],
        [],
        done,
      );
    });
  });

  describe('fetchJobs', () => {
    const stage = {
      id: 1,
      dropdownPath: `${gl.TEST_HOST}/jobs`,
    };

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(stage.dropdownPath).replyOnce(200, jobs);
      });

      it('dispatches request', done => {
        testAction(
          fetchJobs,
          stage,
          mockedState,
          [],
          [
            { type: 'requestJobs', payload: stage.id },
            { type: 'receiveJobsSuccess', payload: { id: stage.id, data: jobs } },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(stage.dropdownPath).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchJobs,
          stage,
          mockedState,
          [],
          [
            { type: 'requestJobs', payload: stage.id },
            { type: 'receiveJobsError', payload: stage.id },
          ],
          done,
        );
      });
    });
  });

  describe('toggleStageCollapsed', () => {
    it('commits collapse', done => {
      testAction(
        toggleStageCollapsed,
        1,
        mockedState,
        [{ type: types.TOGGLE_STAGE_COLLAPSE, payload: 1 }],
        [],
        done,
      );
    });
  });

  describe('setDetailJob', () => {
    it('commits job', done => {
      testAction(
        setDetailJob,
        'job',
        mockedState,
        [{ type: types.SET_DETAIL_JOB, payload: 'job' }],
        [{ type: 'setRightPane' }],
        done,
      );
    });

    it('dispatches setRightPane as pipeline when job is null', done => {
      testAction(
        setDetailJob,
        null,
        mockedState,
        [{ type: types.SET_DETAIL_JOB }],
        [{ type: 'setRightPane', payload: rightSidebarViews.pipelines }],
        done,
      );
    });

    it('dispatches setRightPane as job', done => {
      testAction(
        setDetailJob,
        'job',
        mockedState,
        [{ type: types.SET_DETAIL_JOB }],
        [{ type: 'setRightPane', payload: rightSidebarViews.jobsDetail }],
        done,
      );
    });
  });

  describe('requestJobTrace', () => {
    it('commits request', done => {
      testAction(requestJobTrace, null, mockedState, [{ type: types.REQUEST_JOB_TRACE }], [], done);
    });
  });

  describe('receiveJobTraceError', () => {
    it('commits error', done => {
      testAction(
        receiveJobTraceError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOB_TRACE_ERROR }],
        [],
        done,
      );
    });

    it('creates flash message', () => {
      const flashSpy = spyOnDependency(actions, 'flash');

      receiveJobTraceError({ commit() {} });

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveJobTraceSuccess', () => {
    it('commits data', done => {
      testAction(
        receiveJobTraceSuccess,
        'data',
        mockedState,
        [{ type: types.RECEIVE_JOB_TRACE_SUCCESS, payload: 'data' }],
        [],
        done,
      );
    });
  });

  describe('fetchJobTrace', () => {
    beforeEach(() => {
      mockedState.detailJob = {
        path: `${gl.TEST_HOST}/project/builds`,
      };
    });

    describe('success', () => {
      beforeEach(() => {
        spyOn(axios, 'get').and.callThrough();
        mock.onGet(`${gl.TEST_HOST}/project/builds/trace`).replyOnce(200, { html: 'html' });
      });

      it('dispatches request', done => {
        testAction(
          fetchJobTrace,
          null,
          mockedState,
          [],
          [
            { type: 'requestJobTrace' },
            { type: 'receiveJobTraceSuccess', payload: { html: 'html' } },
          ],
          done,
        );
      });

      it('sends get request to correct URL', () => {
        fetchJobTrace({ state: mockedState, dispatch() {} });

        expect(axios.get).toHaveBeenCalledWith(`${gl.TEST_HOST}/project/builds/trace`, {
          params: { format: 'json' },
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${gl.TEST_HOST}/project/builds/trace`).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchJobTrace,
          null,
          mockedState,
          [],
          [{ type: 'requestJobTrace' }, { type: 'receiveJobTraceError' }],
          done,
        );
      });
    });
  });
});
