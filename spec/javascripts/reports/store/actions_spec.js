import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import {
  setEndpoint,
  requestReports,
  fetchReports,
  stopPolling,
  clearEtagPoll,
  receiveReportsSuccess,
  receiveReportsError,
} from '~/reports/store/actions';
import state from '~/reports/store/state';
import * as types from '~/reports/store/mutation_types';
import testAction from 'spec/helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

describe('Reports Store Actions', () => {
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

  describe('requestReports', () => {
    it('should commit REQUEST_REPORTS mutation', done => {
      testAction(requestReports, null, mockedState, [{ type: types.REQUEST_REPORTS }], [], done);
    });
  });

  describe('fetchReports', () => {
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
      it('dispatches requestReports and receiveReportsSuccess ', done => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(200, { summary: {}, suites: [{ name: 'rspec' }] });

        testAction(
          fetchReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestReports',
            },
            {
              payload: { summary: {}, suites: [{ name: 'rspec' }] },
              type: 'receiveReportsSuccess',
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

      it('dispatches requestReports and receiveReportsError ', done => {
        testAction(
          fetchReports,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestReports',
            },
            {
              type: 'receiveReportsError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveReportsSuccess', () => {
    it('should commit RECEIVE_REPORTS_SUCCESS mutation', done => {
      testAction(
        receiveReportsSuccess,
        { summary: {} },
        mockedState,
        [{ type: types.RECEIVE_REPORTS_SUCCESS, payload: { summary: {} } }],
        [],
        done,
      );
    });
  });

  describe('receiveReportsError', () => {
    it('should commit RECEIVE_REPORTS_ERROR mutation', done => {
      testAction(
        receiveReportsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_REPORTS_ERROR }],
        [],
        done,
      );
    });
  });
});
