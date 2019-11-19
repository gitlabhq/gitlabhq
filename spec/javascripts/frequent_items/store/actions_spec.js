import testAction from 'spec/helpers/vuex_action_helper';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AccessorUtilities from '~/lib/utils/accessor';
import * as actions from '~/frequent_items/store/actions';
import * as types from '~/frequent_items/store/mutation_types';
import state from '~/frequent_items/store/state';
import {
  mockNamespace,
  mockStorageKey,
  mockFrequentProjects,
  mockSearchedProjects,
} from '../mock_data';

describe('Frequent Items Dropdown Store Actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);

    mockedState.namespace = mockNamespace;
    mockedState.storageKey = mockStorageKey;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setNamespace', () => {
    it('should set namespace', done => {
      testAction(
        actions.setNamespace,
        mockNamespace,
        mockedState,
        [{ type: types.SET_NAMESPACE, payload: mockNamespace }],
        [],
        done,
      );
    });
  });

  describe('setStorageKey', () => {
    it('should set storage key', done => {
      testAction(
        actions.setStorageKey,
        mockStorageKey,
        mockedState,
        [{ type: types.SET_STORAGE_KEY, payload: mockStorageKey }],
        [],
        done,
      );
    });
  });

  describe('requestFrequentItems', () => {
    it('should request frequent items', done => {
      testAction(
        actions.requestFrequentItems,
        null,
        mockedState,
        [{ type: types.REQUEST_FREQUENT_ITEMS }],
        [],
        done,
      );
    });
  });

  describe('receiveFrequentItemsSuccess', () => {
    it('should set frequent items', done => {
      testAction(
        actions.receiveFrequentItemsSuccess,
        mockFrequentProjects,
        mockedState,
        [{ type: types.RECEIVE_FREQUENT_ITEMS_SUCCESS, payload: mockFrequentProjects }],
        [],
        done,
      );
    });
  });

  describe('receiveFrequentItemsError', () => {
    it('should set frequent items error state', done => {
      testAction(
        actions.receiveFrequentItemsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_FREQUENT_ITEMS_ERROR }],
        [],
        done,
      );
    });
  });

  describe('fetchFrequentItems', () => {
    it('should dispatch `receiveFrequentItemsSuccess`', done => {
      mockedState.namespace = mockNamespace;
      mockedState.storageKey = mockStorageKey;

      testAction(
        actions.fetchFrequentItems,
        null,
        mockedState,
        [],
        [{ type: 'requestFrequentItems' }, { type: 'receiveFrequentItemsSuccess', payload: [] }],
        done,
      );
    });

    it('should dispatch `receiveFrequentItemsError`', done => {
      spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').and.returnValue(false);
      mockedState.namespace = mockNamespace;
      mockedState.storageKey = mockStorageKey;

      testAction(
        actions.fetchFrequentItems,
        null,
        mockedState,
        [],
        [{ type: 'requestFrequentItems' }, { type: 'receiveFrequentItemsError' }],
        done,
      );
    });
  });

  describe('requestSearchedItems', () => {
    it('should request searched items', done => {
      testAction(
        actions.requestSearchedItems,
        null,
        mockedState,
        [{ type: types.REQUEST_SEARCHED_ITEMS }],
        [],
        done,
      );
    });
  });

  describe('receiveSearchedItemsSuccess', () => {
    it('should set searched items', done => {
      testAction(
        actions.receiveSearchedItemsSuccess,
        mockSearchedProjects,
        mockedState,
        [{ type: types.RECEIVE_SEARCHED_ITEMS_SUCCESS, payload: mockSearchedProjects }],
        [],
        done,
      );
    });
  });

  describe('receiveSearchedItemsError', () => {
    it('should set searched items error state', done => {
      testAction(
        actions.receiveSearchedItemsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_SEARCHED_ITEMS_ERROR }],
        [],
        done,
      );
    });
  });

  describe('fetchSearchedItems', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
    });

    it('should dispatch `receiveSearchedItemsSuccess`', done => {
      mock.onGet(/\/api\/v4\/projects.json(.*)$/).replyOnce(200, mockSearchedProjects, {});

      testAction(
        actions.fetchSearchedItems,
        null,
        mockedState,
        [],
        [
          { type: 'requestSearchedItems' },
          {
            type: 'receiveSearchedItemsSuccess',
            payload: { data: mockSearchedProjects, headers: {} },
          },
        ],
        done,
      );
    });

    it('should dispatch `receiveSearchedItemsError`', done => {
      gon.api_version = 'v4';
      mock.onGet(/\/api\/v4\/projects.json(.*)$/).replyOnce(500);

      testAction(
        actions.fetchSearchedItems,
        null,
        mockedState,
        [],
        [{ type: 'requestSearchedItems' }, { type: 'receiveSearchedItemsError' }],
        done,
      );
    });
  });

  describe('setSearchQuery', () => {
    it('should commit query and dispatch `fetchSearchedItems` when query is present', done => {
      testAction(
        actions.setSearchQuery,
        { query: 'test' },
        mockedState,
        [{ type: types.SET_SEARCH_QUERY, payload: { query: 'test' } }],
        [{ type: 'fetchSearchedItems', payload: { query: 'test' } }],
        done,
      );
    });

    it('should commit query and dispatch `fetchFrequentItems` when query is empty', done => {
      testAction(
        actions.setSearchQuery,
        null,
        mockedState,
        [{ type: types.SET_SEARCH_QUERY, payload: null }],
        [{ type: 'fetchFrequentItems' }],
        done,
      );
    });
  });
});
