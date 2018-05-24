import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import actions, {
  requestLatestPipeline,
  receiveLatestPipelineError,
  receiveLatestPipelineSuccess,
  fetchLatestPipeline,
  requestStages,
  receiveStagesError,
  receiveStagesSuccess,
  fetchStages,
} from '~/ide/stores/modules/pipelines/actions';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import testAction from '../../../../helpers/vuex_action_helper';
import { pipelines, stages } from '../../../mock_data';

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

  describe('requestStages', () => {
    it('commits request', done => {
      testAction(requestStages, null, mockedState, [{ type: types.REQUEST_STAGES }], [], done);
    });
  });

  describe('receiveJobsError', () => {
    it('commits error', done => {
      testAction(
        receiveStagesError,
        null,
        mockedState,
        [{ type: types.RECEIVE_STAGES_ERROR }],
        [],
        done,
      );
    });

    it('creates flash message', () => {
      const flashSpy = spyOnDependency(actions, 'flash');

      receiveStagesError({ commit() {} });

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveStagesSuccess', () => {
    it('commits jobs', done => {
      testAction(
        receiveStagesSuccess,
        stages,
        mockedState,
        [{ type: types.RECEIVE_STAGES_SUCCESS, payload: stages }],
        [],
        done,
      );
    });
  });

  describe('fetchStages', () => {
    beforeEach(() => {
      mockedState.latestPipeline = pipelines[0];
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/\/(.*)\/pipelines\/(.*)\/builds.json/).replyOnce(200, stages);
      });

      it('dispatches request', done => {
        testAction(
          fetchStages,
          null,
          mockedState,
          [],
          [{ type: 'requestStages' }, { type: 'receiveStagesSuccess' }],
          done,
        );
      });

      it('dispatches success with latest pipeline', done => {
        testAction(
          fetchStages,
          null,
          mockedState,
          [],
          [{ type: 'requestStages' }, { type: 'receiveStagesSuccess', payload: stages }],
          done,
        );
      });

      it('calls axios with correct URL', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchStages({ dispatch() {}, state: mockedState, rootState: mockedState });

        expect(apiSpy).toHaveBeenCalledWith(
          '/test/project/pipelines/1/builds.json',
          jasmine.anything(),
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/\/(.*)\/pipelines\/(.*)\/builds.json/).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchStages,
          null,
          mockedState,
          [],
          [{ type: 'requestStages' }, { type: 'receiveStagesError' }],
          done,
        );
      });
    });
  });
});
