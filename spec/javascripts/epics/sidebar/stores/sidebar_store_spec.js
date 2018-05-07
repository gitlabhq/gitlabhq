import SidebarStore from 'ee/epics/sidebar/stores/sidebar_store';

describe('Sidebar Store', () => {
  const dateString = '2017-01-20';

  describe('constructor', () => {
    it('should set startDate', () => {
      const store = new SidebarStore({
        startDate: dateString,
      });
      expect(store.startDate).toEqual(dateString);
    });

    it('should set endDate', () => {
      const store = new SidebarStore({
        endDate: dateString,
      });
      expect(store.endDate).toEqual(dateString);
    });
  });

  describe('startDateTime', () => {
    it('should return null when there is no startDate', () => {
      const store = new SidebarStore({});
      expect(store.startDateTime).toEqual(null);
    });

    it('should return date', () => {
      const store = new SidebarStore({
        startDate: dateString,
      });
      const date = store.startDateTime;

      expect(date.getDate()).toEqual(20);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2017);
    });
  });

  describe('endDateTime', () => {
    it('should return null when there is no endDate', () => {
      const store = new SidebarStore({});
      expect(store.endDateTime).toEqual(null);
    });

    it('should return date', () => {
      const store = new SidebarStore({
        endDate: dateString,
      });
      const date = store.endDateTime;

      expect(date.getDate()).toEqual(20);
      expect(date.getMonth()).toEqual(0);
      expect(date.getFullYear()).toEqual(2017);
    });
  });

  describe('setSubscribed', () => {
    it('should set store.subscribed value', () => {
      const store = new SidebarStore({ subscribed: true });

      store.setSubscribed(false);
      expect(store.subscribed).toEqual(false);
    });
  });
});
