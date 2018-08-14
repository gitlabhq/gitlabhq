import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import state from '~/ide/stores/modules/merge_requests/state';
import * as types from '~/ide/stores/modules/merge_requests/mutation_types';
import {
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
    it('should commit request', done => {
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
    it('should should commit error', done => {
      testAction(
        receiveMergeRequestsError,
        { type: 'created', search: '' },
        mockedState,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR }],
        [
          {
            type: 'setErrorMessage',
            payload: {
              text: 'Error loading merge requests.',
              action: jasmine.any(Function),
              actionText: 'Please try again',
              actionPayload: { type: 'created', search: '' },
            },
          },
        ],
        done,
      );
    });
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('should commit received data', done => {
      testAction(
        receiveMergeRequestsSuccess,
        mergeRequests,
        mockedState,
        [
          {
            type: types.RECEIVE_MERGE_REQUESTS_SUCCESS,
            payload: mergeRequests,
          },
        ],
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

      it('calls API with params', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchMergeRequests({ dispatch() {}, state: mockedState }, { type: 'created' });

        expect(apiSpy).toHaveBeenCalledWith(jasmine.anything(), {
          params: {
            scope: 'created-by-me',
            state: 'opened',
            search: '',
          },
        });
      });

      it('calls API with search', () => {
        const apiSpy = spyOn(axios, 'get').and.callThrough();

        fetchMergeRequests(
          { dispatch() {}, state: mockedState },
          { type: 'created', search: 'testing search' },
        );

        expect(apiSpy).toHaveBeenCalledWith(jasmine.anything(), {
          params: {
            scope: 'created-by-me',
            state: 'opened',
            search: 'testing search',
          },
        });
      });

      it('dispatches success with received data', done => {
        testAction(
          fetchMergeRequests,
          { type: 'created' },
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            {
              type: 'receiveMergeRequestsSuccess',
              payload: mergeRequests,
            },
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
          { type: 'created', search: '' },
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            { type: 'receiveMergeRequestsError', payload: { type: 'created', search: '' } },
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
