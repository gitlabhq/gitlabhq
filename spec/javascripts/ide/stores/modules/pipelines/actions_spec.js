import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import actions, {
  requestLatestPipeline,
  receiveLatestPipelineError,
  receiveLatestPipelineSuccess,
  fetchLatestPipeline,
  requestJobs,
  receiveJobsError,
  receiveJobsSuccess,
  fetchJobs,
} from '~/ide/stores/modules/pipelines/actions';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
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
        [],
        done,
      );
    });

    it('creates flash message', () => {
      const flashSpy = spyOnDependency(actions, 'flash');

      receiveLatestPipelineError({ commit() {} });

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveLatestPipelineSuccess', () => {
    it('commits pipeline', done => {
      testAction(
        receiveLatestPipelineSuccess,
        pipelines[0],
        mockedState,
        [{ type: types.RECEIVE_LASTEST_PIPELINE_SUCCESS, payload: pipelines[0] }],
        [],
        done,
      );
    });
  });

  describe('fetchLatestPipeline', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/projects\/(.*)\/pipelines(.*)/).replyOnce(200, pipelines);
      });

      it('dispatches request', done => {
        testAction(
          fetchLatestPipeline,
          '123',
          mockedState,
          [],
          [{ type: 'requestLatestPipeline' }, { type: 'receiveLatestPipelineSuccess' }],
          done,
        );
      });

      it('dispatches success with latest pipeline', done => {
        testAction(
          fetchLatestPipeline,
          '123',
          mockedState,
          [],
          [
            { type: 'requestLatestPipeline' },
            { type: 'receiveLatestPipelineSuccess', payload: pipelines[0] },
          ],
          done,
        );
      });

      it('calls axios with correct params', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchLatestPipeline({ dispatch() {}, rootState: state }, '123');

        expect(apiSpy).toHaveBeenCalledWith(jasmine.anything(), {
          params: {
            sha: '123',
            per_page: '1',
          },
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/projects\/(.*)\/pipelines(.*)/).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchLatestPipeline,
          '123',
          mockedState,
          [],
          [{ type: 'requestLatestPipeline' }, { type: 'receiveLatestPipelineError' }],
          done,
        );
      });
    });
  });

  describe('requestJobs', () => {
    it('commits request', done => {
      testAction(requestJobs, null, mockedState, [{ type: types.REQUEST_JOBS }], [], done);
    });
  });

  describe('receiveJobsError', () => {
    it('commits error', done => {
      testAction(
        receiveJobsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_JOBS_ERROR }],
        [],
        done,
      );
    });

    it('creates flash message', () => {
      const flashSpy = spyOnDependency(actions, 'flash');

      receiveJobsError({ commit() {} });

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveJobsSuccess', () => {
    it('commits jobs', done => {
      testAction(
        receiveJobsSuccess,
        jobs,
        mockedState,
        [{ type: types.RECEIVE_JOBS_SUCCESS, payload: jobs }],
        [],
        done,
      );
    });
  });

  describe('fetchJobs', () => {
    let page = '';

    beforeEach(() => {
      mockedState.latestPipeline = pipelines[0];
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/projects\/(.*)\/pipelines\/(.*)\/jobs/).replyOnce(() => [
          200,
          jobs,
          {
            'x-next-page': page,
          },
        ]);
      });

      it('dispatches request', done => {
        testAction(
          fetchJobs,
          null,
          mockedState,
          [],
          [{ type: 'requestJobs' }, { type: 'receiveJobsSuccess' }],
          done,
        );
      });

      it('dispatches success with latest pipeline', done => {
        testAction(
          fetchJobs,
          null,
          mockedState,
          [],
          [{ type: 'requestJobs' }, { type: 'receiveJobsSuccess', payload: jobs }],
          done,
        );
      });

      it('dispatches twice for both pages', done => {
        page = '2';

        testAction(
          fetchJobs,
          null,
          mockedState,
          [],
          [
            { type: 'requestJobs' },
            { type: 'receiveJobsSuccess', payload: jobs },
            { type: 'fetchJobs', payload: '2' },
            { type: 'requestJobs' },
            { type: 'receiveJobsSuccess', payload: jobs },
          ],
          done,
        );
      });

      it('calls axios with correct URL', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchJobs({ dispatch() {}, state: mockedState, rootState: mockedState });

        expect(apiSpy).toHaveBeenCalledWith('/api/v4/projects/test%2Fproject/pipelines/1/jobs', {
          params: { page: '1' },
        });
      });

      it('calls axios with page next page', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchJobs({ dispatch() {}, state: mockedState, rootState: mockedState });

        expect(apiSpy).toHaveBeenCalledWith('/api/v4/projects/test%2Fproject/pipelines/1/jobs', {
          params: { page: '1' },
        });

        page = '2';

        fetchJobs({ dispatch() {}, state: mockedState, rootState: mockedState }, page);

        expect(apiSpy).toHaveBeenCalledWith('/api/v4/projects/test%2Fproject/pipelines/1/jobs', {
          params: { page: '2' },
        });
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/projects\/(.*)\/pipelines(.*)/).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchJobs,
          null,
          mockedState,
          [],
          [{ type: 'requestJobs' }, { type: 'receiveJobsError' }],
          done,
        );
      });
    });
  });
});
