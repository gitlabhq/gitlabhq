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
  openMergeRequest,
} from '~/ide/stores/modules/merge_requests/actions';
import router from '~/ide/ide_router';
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
        'created',
        mockedState,
        [{ type: types.REQUEST_MERGE_REQUESTS, payload: 'created' }],
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
        'created',
        mockedState,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR, payload: 'created' }],
        [],
        done,
      );
    });

    it('creates flash message', () => {
      receiveMergeRequestsError({ commit() {} }, 'created');

      expect(flashSpy).toHaveBeenCalled();
    });
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('should commit received data', done => {
      testAction(
        receiveMergeRequestsSuccess,
        { type: 'created', data: 'data' },
        mockedState,
        [
          {
            type: types.RECEIVE_MERGE_REQUESTS_SUCCESS,
            payload: { type: 'created', data: 'data' },
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

      it('dispatches request', done => {
        testAction(
          fetchMergeRequests,
          { type: 'created' },
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
          { type: 'created' },
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            { type: 'resetMergeRequests' },
            {
              type: 'receiveMergeRequestsSuccess',
              payload: { type: 'created', data: mergeRequests },
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
          { type: 'created' },
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
        'created',
        mockedState,
        [{ type: types.RESET_MERGE_REQUESTS, payload: 'created' }],
        [],
        done,
      );
    });
  });

  describe('openMergeRequest', () => {
    beforeEach(() => {
      spyOn(router, 'push');
    });

    it('commits reset mutations and actions', done => {
      const commit = jasmine.createSpy();
      const dispatch = jasmine.createSpy().and.returnValue(Promise.resolve());
      openMergeRequest({ commit, dispatch }, { projectPath: 'gitlab-org/gitlab-ce', id: '1' });

      setTimeout(() => {
        expect(commit.calls.argsFor(0)).toEqual(['CLEAR_PROJECTS', null, { root: true }]);
        expect(commit.calls.argsFor(1)).toEqual(['SET_CURRENT_MERGE_REQUEST', '1', { root: true }]);
        expect(commit.calls.argsFor(2)).toEqual(['RESET_OPEN_FILES', null, { root: true }]);

        expect(dispatch.calls.argsFor(0)).toEqual([
          'pipelines/resetLatestPipeline',
          null,
          { root: true },
        ]);
        expect(dispatch.calls.argsFor(1)).toEqual(['setCurrentBranchId', '', { root: true }]);
        expect(dispatch.calls.argsFor(2)).toEqual([
          'pipelines/stopPipelinePolling',
          null,
          { root: true },
        ]);
        expect(dispatch.calls.argsFor(3)).toEqual([
          'pipelines/clearEtagPoll',
          null,
          { root: true },
        ]);

        done();
      });
    });

    it('pushes new route', () => {
      openMergeRequest(
        { commit() {}, dispatch: () => Promise.resolve() },
        { projectPath: 'gitlab-org/gitlab-ce', id: '1' },
      );

      expect(router.push).toHaveBeenCalledWith('/project/gitlab-org/gitlab-ce/merge_requests/1');
    });
  });
});
