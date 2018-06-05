import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import state from '~/ide/stores/modules/merge_requests/state';
import * as types from '~/ide/stores/modules/merge_requests/mutation_types';
import actions, {
  requestMergeRequests,
  receiveMergeRequestsError,
  receiveMergeRequestsSuccess,
  fetchMergeRequests,
  resetMergeRequests,
} from '~/ide/stores/modules/merge_requests/actions';
import { mergeRequests } from '../../../mock_data';
import testAction from '../../../../helpers/vuex_action_helper';

describe('IDE merge requests actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestMergeRequests', () => {
    it('should should commit request', done => {
      testAction(
        requestMergeRequests,
        null,
        mockedState,
        [{ type: types.REQUEST_MERGE_REQUESTS }],
        [],
        done,
      );
    });
  });

  describe('receiveMergeRequestsError', () => {
    let flashSpy;

    beforeEach(() => {
      flashSpy = spyOnDependency(actions, 'flash');
    });

    it('should should commit error', done => {
      testAction(
        receiveMergeRequestsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR }],
        [],
        done,
      );
    });

    it('creates flash message', () => {
      receiveMergeRequestsError({ commit() {} });

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('should commit received data', done => {
      testAction(
        receiveMergeRequestsSuccess,
        'data',
        mockedState,
        [{ type: types.RECEIVE_MERGE_REQUESTS_SUCCESS, payload: 'data' }],
        [],
        done,
      );
    });
  });

  describe('fetchMergeRequests', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/merge_requests(.*)$/).replyOnce(200, mergeRequests);
      });

      it('calls API with params from state', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchMergeRequests({ dispatch() {}, state: mockedState });

        expect(apiSpy).toHaveBeenCalledWith(jasmine.anything(), {
          params: {
            scope: 'assigned-to-me',
            state: 'opened',
            search: '',
          },
        });
      });

      it('calls API with search', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchMergeRequests({ dispatch() {}, state: mockedState }, 'testing search');

        expect(apiSpy).toHaveBeenCalledWith(jasmine.anything(), {
          params: {
            scope: 'assigned-to-me',
            state: 'opened',
            search: 'testing search',
          },
        });
      });

      it('dispatches request', done => {
        testAction(
          fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsSuccess' },
          ],
          done,
        );
      });

      it('dispatches success with received data', done => {
        testAction(
          fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsSuccess', payload: mergeRequests },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/\/api\/v4\/merge_requests(.*)$/).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsError' },
          ],
          done,
        );
      });
    });
  });

  describe('resetMergeRequests', () => {
    it('commits reset', done => {
      testAction(
        resetMergeRequests,
        null,
        mockedState,
        [{ type: types.RESET_MERGE_REQUESTS }],
        [],
        done,
      );
    });
  });
});
