import testAction from 'spec/helpers/vuex_action_helper';
import {
  requestReleases,
  fetchReleases,
  receiveReleasesSuccess,
  receiveReleasesError,
} from '~/releases/list/store/actions';
import state from '~/releases/list/store/state';
import * as types from '~/releases/list/store/mutation_types';
import api from '~/api';
import { parseIntPagination } from '~/lib/utils/common_utils';
import { pageInfoHeadersWithoutPagination, releases } from '../../mock_data';

describe('Releases State actions', () => {
  let mockedState;
  let pageInfo;

  beforeEach(() => {
    mockedState = state();
    pageInfo = parseIntPagination(pageInfoHeadersWithoutPagination);
  });

  describe('requestReleases', () => {
    it('should commit REQUEST_RELEASES mutation', done => {
      testAction(requestReleases, null, mockedState, [{ type: types.REQUEST_RELEASES }], [], done);
    });
  });

  describe('fetchReleases', () => {
    describe('success', () => {
      it('dispatches requestReleases and receiveReleasesSuccess', done => {
        spyOn(api, 'releases').and.callFake((id, options) => {
          expect(id).toEqual(1);
          expect(options.page).toEqual('1');
          return Promise.resolve({ data: releases, headers: pageInfoHeadersWithoutPagination });
        });

        testAction(
          fetchReleases,
          { projectId: 1 },
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              payload: { data: releases, headers: pageInfoHeadersWithoutPagination },
              type: 'receiveReleasesSuccess',
            },
          ],
          done,
        );
      });

      it('dispatches requestReleases and receiveReleasesSuccess on page two', done => {
        spyOn(api, 'releases').and.callFake((_, options) => {
          expect(options.page).toEqual('2');
          return Promise.resolve({ data: releases, headers: pageInfoHeadersWithoutPagination });
        });

        testAction(
          fetchReleases,
          { page: '2', projectId: 1 },
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              payload: { data: releases, headers: pageInfoHeadersWithoutPagination },
              type: 'receiveReleasesSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestReleases and receiveReleasesError', done => {
        spyOn(api, 'releases').and.returnValue(Promise.reject());

        testAction(
          fetchReleases,
          { projectId: null },
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              type: 'receiveReleasesError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveReleasesSuccess', () => {
    it('should commit RECEIVE_RELEASES_SUCCESS mutation', done => {
      testAction(
        receiveReleasesSuccess,
        { data: releases, headers: pageInfoHeadersWithoutPagination },
        mockedState,
        [{ type: types.RECEIVE_RELEASES_SUCCESS, payload: { pageInfo, data: releases } }],
        [],
        done,
      );
    });
  });

  describe('receiveReleasesError', () => {
    it('should commit RECEIVE_RELEASES_ERROR mutation', done => {
      testAction(
        receiveReleasesError,
        null,
        mockedState,
        [{ type: types.RECEIVE_RELEASES_ERROR }],
        [],
        done,
      );
    });
  });
});
