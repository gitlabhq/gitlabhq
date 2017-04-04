import '~/flash';
import SidebarAssigneesStore from '~/vue_sidebar_assignees/stores/sidebar_assignees_store';
import { mockUser } from '../mock_data';

describe('SidebarAssigneesStore', () => {
  let params;

  beforeEach(() => {
    params = {
      currentUserId: 1,
      service: {
        update: () => {},
      },
      rootPath: 'rootPath',
      editable: true,
    };
  });

  const getStore = p => new SidebarAssigneesStore(p);

  it('should store information', () => {
    const store = getStore(params);
    Object.keys(params).forEach((k) => {
      expect(store[k]).toEqual(params[k]);
    });
  });

  describe('addUser', () => {
    let store;
    beforeEach(() => {
      store = getStore(params);
    });

    it('should add user to users array', () => {
      expect(store.users.length).toEqual(0);
      store.addUser(mockUser);

      expect(store.users.length).toEqual(1);
      expect(store.users[0]).toEqual(mockUser);
      expect(store.saved).toEqual(false);
    });

    it('should set saved flag to true if second param is true', () => {
      store.addUser(mockUser, true);
      expect(store.saved).toEqual(true);
    });
  });

  describe('addCurrentUser', () => {
    let store;
    beforeEach(() => {
      store = getStore(params);
      spyOn(store, 'saveUsers').and.callFake(() => {});
    });

    it('should add current user to users array', () => {
      spyOn(store, 'addUser').and.callThrough();

      store.addCurrentUser();
      expect(store.addUser).toHaveBeenCalledWith({
        id: 1,
      });
    });

    it('should call saveUsers', () => {
      store.addCurrentUser();
      expect(store.saveUsers).toHaveBeenCalled();
    });
  });

  describe('removeUser', () => {
    let store;
    beforeEach(() => {
      store = getStore(params);
      store.addUser(mockUser, true);
    });

    it('should remove user from users array', () => {
      expect(store.users.length).toEqual(1);
      store.removeUser(mockUser.id);
      expect(store.users.length).toEqual(0);
    });

    it('should set saved flag to false', () => {
      expect(store.saved).toEqual(true);
      store.removeUser(mockUser.id);
      expect(store.saved).toEqual(false);
    });
  });

  describe('saveUsers', () => {
    it('should save unassigned user when there are no users2', () => {
      const spyParams = Object.assign({}, params);
      const store = getStore(spyParams);

      spyOn(spyParams.service, 'update').and.callFake(() =>
        new Promise(resolve =>
          resolve({
            data: {
              assignees: [],
            },
          }),
        ),
      );
      store.saveUsers();

      expect(spyParams.service.update).toHaveBeenCalledWith([0]);
      expect(store.users.length).toEqual(0);
    });

    it('should catch error', () => {
      const spyParams = Object.assign({}, params);
      const store = getStore(spyParams);

      spyOn(window, 'Flash').and.callThrough();
      spyOn(spyParams.service, 'update').and.callFake(() =>
        new Promise((resolve, reject) => reject()),
      );
      store.saveUsers();

      setTimeout(() => {
        expect(window.Flash).toHaveBeenCalled();
      });
    });

    it('should save unassigned user when there are no users', () => {
      const spyParams = Object.assign({}, params);
      const store = getStore(spyParams);

      spyOn(spyParams.service, 'update').and.callFake(() =>
        new Promise(resolve =>
          resolve({
            data: {
              assignees: [],
            },
          }),
        ),
      );
      store.saveUsers();

      expect(spyParams.service.update).toHaveBeenCalledWith([0]);
      expect(store.users.length).toEqual(0);
    });
  });
});
