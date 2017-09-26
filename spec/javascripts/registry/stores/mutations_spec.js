import mutations from '~/registry/stores/mutations';
import * as types from '~/registry/stores/mutation_types';
import {
  defaultState,
  reposServerResponse,
  registryServerResponse,
  parsedReposServerResponse,
  parsedRegistryServerResponse,
} from '../mock_data';

describe('Mutations Registry Store', () => {
  let mockState;
  beforeEach(() => {
    mockState = defaultState;
  });

  describe('SET_MAIN_ENDPOINT', () => {
    it('should set the main endpoint', () => {
      const expectedState = Object.assign({}, mockState, { endpoint: 'foo' });
      mutations[types.SET_MAIN_ENDPOINT](mockState, 'foo');
      expect(mockState).toEqual(expectedState);
    });
  });

  describe('SET_REPOS_LIST', () => {
    it('should set a parsed repository list', () => {
      mutations[types.SET_REPOS_LIST](mockState, reposServerResponse);
      expect(mockState.repos).toEqual(parsedReposServerResponse);
    });
  });

  describe('TOGGLE_MAIN_LOADING', () => {
    it('should set a parsed repository list', () => {
      mutations[types.TOGGLE_MAIN_LOADING](mockState);
      expect(mockState.isLoading).toEqual(true);
    });
  });

  describe('SET_REGISTRY_LIST', () => {
    it('should set a list of registries in a specific repository', () => {
      mutations[types.SET_REPOS_LIST](mockState, reposServerResponse);
      mutations[types.SET_REGISTRY_LIST](mockState, {
        repo: mockState.repos[0],
        resp: registryServerResponse,
        headers: {
          'x-per-page': 2,
          'x-page': 1,
          'x-total': 10,
        },
      });

      expect(mockState.repos[0].list).toEqual(parsedRegistryServerResponse);
      expect(mockState.repos[0].pagination).toEqual({
        perPage: 2,
        page: 1,
        total: 10,
        totalPages: NaN,
        nextPage: NaN,
        previousPage: NaN,
      });
    });
  });

  describe('TOGGLE_REGISTRY_LIST_LOADING', () => {
    it('should toggle isLoading property for a specific repository', () => {
      mutations[types.SET_REPOS_LIST](mockState, reposServerResponse);
      mutations[types.SET_REGISTRY_LIST](mockState, {
        repo: mockState.repos[0],
        resp: registryServerResponse,
        headers: {
          'x-per-page': 2,
          'x-page': 1,
          'x-total': 10,
        },
      });

      mutations[types.TOGGLE_REGISTRY_LIST_LOADING](mockState, mockState.repos[0]);
      expect(mockState.repos[0].isLoading).toEqual(true);
    });
  });
});
