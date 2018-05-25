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
} from '~/ide/stores/modules/pipelines/actions';
import state from '~/ide/stores/modules/pipelines/state';
import * as types from '~/ide/stores/modules/pipelines/mutation_types';
import testAction from '../../../../helpers/vuex_action_helper';
import { pipelines } from '../../../mock_data';

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
});
