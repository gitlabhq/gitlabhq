import {
  requestReleases,
  fetchReleases,
  receiveReleasesSuccess,
  receiveReleasesError,
} from '~/releases/store/actions';
import state from '~/releases/store/state';
import * as types from '~/releases/store/mutation_types';
import api from '~/api';
import testAction from 'spec/helpers/vuex_action_helper';
import { releases } from '../mock_data';

describe('Releases State actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('requestReleases', () => {
    it('should commit REQUEST_RELEASES mutation', done => {
      testAction(requestReleases, null, mockedState, [{ type: types.REQUEST_RELEASES }], [], done);
    });
  });

  describe('fetchReleases', () => {
    describe('success', () => {
      it('dispatches requestReleases and receiveReleasesSuccess ', done => {
        spyOn(api, 'releases').and.returnValue(Promise.resolve({ data: releases }));

        testAction(
          fetchReleases,
          releases,
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              payload: releases,
              type: 'receiveReleasesSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestReleases and receiveReleasesError ', done => {
        spyOn(api, 'releases').and.returnValue(Promise.reject());

        testAction(
          fetchReleases,
          null,
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
        releases,
        mockedState,
        [{ type: types.RECEIVE_RELEASES_SUCCESS, payload: releases }],
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
