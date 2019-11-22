import state from '~/releases/list/store/state';
import mutations from '~/releases/list/store/mutations';
import * as types from '~/releases/list/store/mutation_types';
import { parseIntPagination } from '~/lib/utils/common_utils';
import { pageInfoHeadersWithoutPagination, releases } from '../../mock_data';

describe('Releases Store Mutations', () => {
  let stateCopy;
  let pageInfo;

  beforeEach(() => {
    stateCopy = state();
    pageInfo = parseIntPagination(pageInfoHeadersWithoutPagination);
  });

  describe('REQUEST_RELEASES', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_RELEASES](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_RELEASES_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_RELEASES_SUCCESS](stateCopy, { pageInfo, data: releases });
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

    it('sets pageInfo', () => {
      expect(stateCopy.pageInfo).toEqual(pageInfo);
    });
  });

  describe('RECEIVE_RELEASES_ERROR', () => {
    it('resets data', () => {
      mutations[types.RECEIVE_RELEASES_ERROR](stateCopy);

      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.releases).toEqual([]);
      expect(stateCopy.pageInfo).toEqual({});
    });
  });
});
