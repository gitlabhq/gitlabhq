import state from '~/releases/store/state';
import mutations from '~/releases/store/mutations';
import * as types from '~/releases/store/mutation_types';
import { releases } from '../mock_data';

describe('Releases Store Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('REQUEST_RELEASES', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_RELEASES](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_RELEASES_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_RELEASES_SUCCESS](stateCopy, releases);
    });

    it('sets is loading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('sets hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('sets data', () => {
      expect(stateCopy.releases).toEqual(releases);
    });
  });

  describe('RECEIVE_RELEASES_ERROR', () => {
    it('resets data', () => {
      mutations[types.RECEIVE_RELEASES_ERROR](stateCopy);

      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.releases).toEqual([]);
    });
  });
});
