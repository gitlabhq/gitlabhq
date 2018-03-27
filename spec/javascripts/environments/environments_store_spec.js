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

  describe('store environments', () => {
    it('should store environments', () => {
      store.storeEnvironments(serverData);
      expect(store.state.environments.length).toEqual(serverData.length);
    });

    it('should add folder keys when environment is a folder', () => {
      const environment = {
        name: 'bar',
        size: 3,
        id: 2,
      };

      store.storeEnvironments([environment]);
      expect(store.state.environments[0].isFolder).toEqual(true);
      expect(store.state.environments[0].folderName).toEqual('bar');
    });

    it('should extract content of `latest` key when provided', () => {
      const environment = {
        name: 'bar',
        size: 3,
        id: 2,
        latest: {
          last_deployment: {},
          isStoppable: true,
        },
      };

      store.storeEnvironments([environment]);
      expect(store.state.environments[0].last_deployment).toEqual({});
      expect(store.state.environments[0].isStoppable).toEqual(true);
    });

    it('should store latest.name when the environment is not a folder', () => {
      store.storeEnvironments(serverData);
      expect(store.state.environments[0].name).toEqual(serverData[0].latest.name);
    });

    it('should store root level name when environment is a folder', () => {
      store.storeEnvironments(serverData);
      expect(store.state.environments[1].folderName).toEqual(serverData[1].name);
    });
  });

  describe('toggleFolder', () => {
    it('should toggle folder', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);
      expect(store.state.environments[1].isOpen).toEqual(true);

      store.toggleFolder(store.state.environments[1]);
      expect(store.state.environments[1].isOpen).toEqual(false);
    });

    it('should keep folder open when environments are updated', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);
      expect(store.state.environments[1].isOpen).toEqual(true);

      store.storeEnvironments(serverData);
      expect(store.state.environments[1].isOpen).toEqual(true);
    });
  });

  describe('setfolderContent', () => {
    it('should store folder content', () => {
      store.storeEnvironments(serverData);

      store.setfolderContent(store.state.environments[1], serverData);

      expect(store.state.environments[1].children.length).toEqual(serverData.length);
      expect(store.state.environments[1].children[0].isChildren).toEqual(true);
    });

    it('should keep folder content when environments are updated', () => {
      store.storeEnvironments(serverData);

      store.setfolderContent(store.state.environments[1], serverData);

      expect(store.state.environments[1].children.length).toEqual(serverData.length);
      // poll
      store.storeEnvironments(serverData);
      expect(store.state.environments[1].children.length).toEqual(serverData.length);
    });
  });

  describe('store pagination', () => {
    it('should store normalized and integer pagination information', () => {
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
  });

  describe('getOpenFolders', () => {
    it('should return open folder', () => {
      store.storeEnvironments(serverData);

      store.toggleFolder(store.state.environments[1]);
      expect(store.getOpenFolders()[0]).toEqual(store.state.environments[1]);
    });
  });
});
