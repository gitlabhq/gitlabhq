import MockAdapter from 'axios-mock-adapter';
import setTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import axios from '~/lib/utils/axios_utils';
import PersistentUserCallout from '~/persistent_user_callout';

describe('PersistentUserCallout', () => {
  const dismissEndpoint = '/dismiss';
  const featureName = 'feature';

  function createFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
      >
        <button type="button" class="js-close"></button>
      </div>
    `;

    return fixture;
  }

  function createDeferredLinkFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
        data-defer-links="true"
      >
        <button type="button" class="js-close"></button>
        <a href="/somewhere-pleasant" target="_blank" class="deferred-link">A link</a>
        <a href="/somewhere-else" target="_blank" class="normal-link">Another link</a>
      </div>
    `;

    return fixture;
  }

  describe('dismiss', () => {
    let button;
    let mockAxios;
    let persistentUserCallout;

    beforeEach(() => {
      const fixture = createFixture();
      const container = fixture.querySelector('.container');
      button = fixture.querySelector('.js-close');
      mockAxios = new MockAdapter(axios);
      persistentUserCallout = new PersistentUserCallout(container);
      spyOn(persistentUserCallout.container, 'remove');
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('POSTs endpoint and removes container when clicking close', done => {
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      button.click();

      setTimeoutPromise()
        .then(() => {
          expect(persistentUserCallout.container.remove).toHaveBeenCalled();
          expect(mockAxios.history.post[0].data).toBe(
            JSON.stringify({ feature_name: featureName }),
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it('invokes Flash when the dismiss request fails', done => {
      const Flash = spyOnDependency(PersistentUserCallout, 'Flash');
      mockAxios.onPost(dismissEndpoint).replyOnce(500);

      button.click();

      setTimeoutPromise()
        .then(() => {
          expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
          expect(Flash).toHaveBeenCalledWith(
            'An error occurred while dismissing the alert. Refresh the page and try again.',
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('deferred links', () => {
    let button;
    let deferredLink;
    let normalLink;
    let mockAxios;
    let persistentUserCallout;
    let windowSpy;

    beforeEach(() => {
      const fixture = createDeferredLinkFixture();
      const container = fixture.querySelector('.container');
      button = fixture.querySelector('.js-close');
      deferredLink = fixture.querySelector('.deferred-link');
      normalLink = fixture.querySelector('.normal-link');
      mockAxios = new MockAdapter(axios);
      persistentUserCallout = new PersistentUserCallout(container);
      spyOn(persistentUserCallout.container, 'remove');
      windowSpy = spyOn(window, 'open').and.callFake(() => {});
    });

    afterEach(() => {
      mockAxios.restore();
    });

    it('defers loading of a link until callout is dismissed', done => {
      const { href, target } = deferredLink;
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      deferredLink.click();

      setTimeoutPromise()
        .then(() => {
          expect(windowSpy).toHaveBeenCalledWith(href, target);
          expect(persistentUserCallout.container.remove).toHaveBeenCalled();
          expect(mockAxios.history.post[0].data).toBe(
            JSON.stringify({ feature_name: featureName }),
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not dismiss callout on non-deferred links', done => {
      normalLink.click();

      setTimeoutPromise()
        .then(() => {
          expect(windowSpy).not.toHaveBeenCalled();
          expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not follow link when notification is closed', done => {
      mockAxios.onPost(dismissEndpoint).replyOnce(200);

      button.click();

      setTimeoutPromise()
        .then(() => {
          expect(windowSpy).not.toHaveBeenCalled();
          expect(persistentUserCallout.container.remove).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('factory', () => {
    it('returns an instance of PersistentUserCallout with the provided container property', () => {
      const fixture = createFixture();

      expect(PersistentUserCallout.factory(fixture) instanceof PersistentUserCallout).toBe(true);
    });

    it('returns undefined if container is falsey', () => {
      expect(PersistentUserCallout.factory()).toBe(undefined);
    });
  });
});
