import state from '~/ide/stores/modules/merge_requests/state';
import mutations from '~/ide/stores/modules/merge_requests/mutations';
import * as types from '~/ide/stores/modules/merge_requests/mutation_types';
import { mergeRequests } from '../../../mock_data';

describe('IDE merge requests mutations', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe(types.REQUEST_MERGE_REQUESTS, () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_MERGE_REQUESTS](mockedState);

      expect(mockedState.isLoading).toBe(true);
    });
  });

  describe(types.RECEIVE_MERGE_REQUESTS_ERROR, () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_MERGE_REQUESTS_ERROR](mockedState);

      expect(mockedState.isLoading).toBe(false);
    });
  });

  describe(types.RECEIVE_MERGE_REQUESTS_SUCCESS, () => {
    it('sets merge requests', () => {
      mutations[types.RECEIVE_MERGE_REQUESTS_SUCCESS](mockedState, mergeRequests);

      expect(mockedState.mergeRequests).toEqual([
        {
          id: 1,
          title: 'Test merge request',
        },
      ]);
    });
  });
});
