const Store = require('~/environments/stores/environments_store');
const { serverData, deployBoardMockData } = require('./mock_data');

(() => {
  describe('Environments Store', () => {
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

    describe('store environments', () => {
      it('should store environments', () => {
        store.storeEnvironments(serverData);
        expect(store.state.environments.length).toEqual(serverData.length);
      });

      it('should store a non folder environment with deploy board if rollout_status_path key is provided', () => {
        const environment = {
          name: 'foo',
          size: 1,
          id: 1,
          rollout_status_path: 'url',
        };

        store.storeEnvironments([environment]);
        expect(store.state.environments[0].hasDeployBoard).toEqual(true);
        expect(store.state.environments[0].isDeployBoardVisible).toEqual(false);
        expect(store.state.environments[0].deployBoardData).toEqual({});
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
    });

    it('should store available count', () => {
      store.storeAvailableCount(2);
      expect(store.state.availableCounter).toEqual(2);
    });

    it('should store stopped count', () => {
      store.storeStoppedCount(2);
      expect(store.state.stoppedCounter).toEqual(2);
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

    describe('deploy boards', () => {
      beforeEach(() => {
        const environment = {
          name: 'foo',
          size: 1,
          id: 1,
        };

        store.storeEnvironments([environment]);
      });

      it('should toggle deploy board property for given environment id', () => {
        store.toggleDeployBoard(1);
        expect(store.state.environments[0].isDeployBoardVisible).toEqual(true);
      });

      it('should store deploy board data for given environment id', () => {
        store.storeDeployBoard(1, deployBoardMockData);
        expect(store.state.environments[0].deployBoardData).toEqual(deployBoardMockData);
      });
    });
  });
})();
