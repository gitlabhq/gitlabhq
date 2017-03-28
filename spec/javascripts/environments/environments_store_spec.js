import Store from '~/environments/stores/environments_store';
import { environmentsList, serverData } from './mock_data';

describe('Store', () => {
  let store;

  beforeEach(() => {
    store = new Store();
  });

  it('should start with a blank state', () => {
    expect(store.state.environments.length).toEqual(0);
    expect(store.state.stoppedCounter).toEqual(0);
    expect(store.state.availableCounter).toEqual(0);
    expect(store.state.paginationInformation).toEqual({});
  });

  it('should store environments', () => {
    store.storeEnvironments(serverData);
    expect(store.state.environments.length).toEqual(serverData.length);
    expect(store.state.environments[0]).toEqual(environmentsList[0]);
  });

  it('should store available count', () => {
    store.storeAvailableCount(2);
    expect(store.state.availableCounter).toEqual(2);
  });

  it('should store stopped count', () => {
    store.storeStoppedCount(2);
    expect(store.state.stoppedCounter).toEqual(2);
  });

  it('should store pagination information', () => {
    const pagination = {
      'X-nExt-pAge': '2',
      'X-page': '1',
      'X-Per-Page': '1',
      'X-Prev-Page': '2',
      'X-TOTAL': '37',
      'X-Total-Pages': '2',
    };

    const expectedResult = {
      perPage: 1,
      page: 1,
      total: 37,
      totalPages: 2,
      nextPage: 2,
      previousPage: 2,
    };

    store.setPagination(pagination);
    expect(store.state.paginationInformation).toEqual(expectedResult);
  });

  describe('toggleFolder', () => {
    it('should toggle folder', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);
      expect(store.state.environments[1].isOpen).toEqual(true);

      store.toggleFolder(store.state.environments[1]);
      expect(store.state.environments[1].isOpen).toEqual(false);
    });
  });

  describe('setfolderContent', () => {
    it('should store folder content', () => {
      store.storeEnvironments(serverData);

      store.setfolderContent(store.state.environments[1], serverData);

      expect(store.state.environments[1].children.length).toEqual(serverData.length);
      expect(store.state.environments[1].children[0].isChildren).toEqual(true);
    });
  });
});
