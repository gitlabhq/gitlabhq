import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import {
  setEndpoint,
  requestArtifacts,
  clearEtagPoll,
  stopPolling,
  fetchArtifacts,
  receiveArtifactsSuccess,
  receiveArtifactsError,
} from '~/vue_merge_request_widget/stores/artifacts_list/actions';
import state from '~/vue_merge_request_widget/stores/artifacts_list/state';
import * as types from '~/vue_merge_request_widget/stores/artifacts_list/mutation_types';

describe('Artifacts App Store Actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setEndpoint', () => {
    it('should commit SET_ENDPOINT mutation', done => {
      testAction(
        setEndpoint,
        'endpoint.json',
        mockedState,
        [{ type: types.SET_ENDPOINT, payload: 'endpoint.json' }],
        [],
        done,
      );
    });
  });

  describe('requestArtifacts', () => {
    it('should commit REQUEST_ARTIFACTS mutation', done => {
      testAction(
        requestArtifacts,
        null,
        mockedState,
        [{ type: types.REQUEST_ARTIFACTS }],
        [],
        done,
      );
    });
  });

  describe('fetchArtifacts', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = `${TEST_HOST}/endpoint.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
      stopPolling();
      clearEtagPoll();
    });

    describe('success', () => {
      it('dispatches requestArtifacts and receiveArtifactsSuccess ', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, [
          {
            text: 'result.txt',
            url: 'asda',
            job_name: 'generate-artifact',
            job_path: 'asda',
          },
        ]);

        testAction(
          fetchArtifacts,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestArtifacts',
            },
            {
              payload: {
                data: [
                  {
                    text: 'result.txt',
                    url: 'asda',
                    job_name: 'generate-artifact',
                    job_path: 'asda',
                  },
                ],
                status: 200,
              },
              type: 'receiveArtifactsSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(500);
      });

      it('dispatches requestArtifacts and receiveArtifactsError ', done => {
        testAction(
          fetchArtifacts,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestArtifacts',
            },
            {
              type: 'receiveArtifactsError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveArtifactsSuccess', () => {
    it('should commit RECEIVE_ARTIFACTS_SUCCESS mutation with 200', done => {
      testAction(
        receiveArtifactsSuccess,
        { data: { summary: {} }, status: 200 },
        mockedState,
        [{ type: types.RECEIVE_ARTIFACTS_SUCCESS, payload: { summary: {} } }],
        [],
        done,
      );
    });

    it('should not commit RECEIVE_ARTIFACTS_SUCCESS mutation with 204', done => {
      testAction(
        receiveArtifactsSuccess,
        { data: { summary: {} }, status: 204 },
        mockedState,
        [],
        [],
        done,
      );
    });
  });

  describe('receiveArtifactsError', () => {
    it('should commit RECEIVE_ARTIFACTS_ERROR mutation', done => {
      testAction(
        receiveArtifactsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_ARTIFACTS_ERROR }],
        [],
        done,
      );
    });
  });
});
