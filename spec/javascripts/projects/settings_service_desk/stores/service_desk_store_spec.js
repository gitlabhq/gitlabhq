import ServiceDeskStore from '~/projects/settings_service_desk/stores/service_desk_store';

describe('ServiceDeskStore', () => {
  let store;

  beforeEach(() => {
    store = new ServiceDeskStore();
  });

  describe('setIsActivated', () => {
    it('defaults to false', () => {
      expect(store.state.isEnabled).toEqual(false);
    });

    it('set true', () => {
      store.setIsActivated(true);

      expect(store.state.isEnabled).toEqual(true);
    });

    it('set false', () => {
      store.setIsActivated(false);

      expect(store.state.isEnabled).toEqual(false);
    });
  });

  describe('setIncomingEmail', () => {
    it('defaults to an empty string', () => {
      expect(store.state.incomingEmail).toEqual('');
    });

    it('set true', () => {
      const email = 'foo@bar.com';
      store.setIncomingEmail(email);

      expect(store.state.incomingEmail).toEqual(email);
    });
  });

  describe('setFetchError', () => {
    it('defaults to null', () => {
      expect(store.state.fetchError).toEqual(null);
    });

    it('set true', () => {
      const err = new Error('some-fake-failure');
      store.setFetchError(err);

      expect(store.state.fetchError).toEqual(err);
    });
  });
});
