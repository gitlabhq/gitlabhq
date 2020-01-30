import initUserPopovers from '~/user_popovers';
import UsersCache from '~/lib/utils/users_cache';

describe('User Popovers', () => {
  const fixtureTemplate = 'merge_requests/diff_comment.html';
  preloadFixtures(fixtureTemplate);

  const selector = '.js-user-link';

  const dummyUser = { name: 'root' };
  const dummyUserStatus = { message: 'active' };

  let popovers;

  const triggerEvent = (eventName, el) => {
    const event = new MouseEvent(eventName, {
      bubbles: true,
      cancelable: true,
      view: window,
    });

    el.dispatchEvent(event);
  };

  beforeEach(() => {
    loadFixtures(fixtureTemplate);

    const usersCacheSpy = () => Promise.resolve(dummyUser);
    spyOn(UsersCache, 'retrieveById').and.callFake(userId => usersCacheSpy(userId));

    const userStatusCacheSpy = () => Promise.resolve(dummyUserStatus);
    spyOn(UsersCache, 'retrieveStatusById').and.callFake(userId => userStatusCacheSpy(userId));

    popovers = initUserPopovers(document.querySelectorAll(selector));
  });

  it('initializes a popover for each js-user-link element found in the document', () => {
    expect(document.querySelectorAll(selector).length).toBe(popovers.length);
  });

  describe('when user link emits mouseenter event', () => {
    let userLink;

    beforeEach(() => {
      userLink = document.querySelector(selector);

      triggerEvent('mouseenter', userLink);
    });

    it('removes title attribute from user links', () => {
      expect(userLink.getAttribute('title')).toBeFalsy();
      expect(userLink.dataset.originalTitle).toBeFalsy();
    });

    it('populates popovers with preloaded user data', () => {
      const { name, userId, username } = userLink.dataset;
      const [firstPopover] = popovers;

      expect(firstPopover.$props.user).toEqual(
        jasmine.objectContaining({
          name,
          userId,
          username,
        }),
      );
    });

    it('fetches user info and status from the user cache', () => {
      const { userId } = userLink.dataset;

      expect(UsersCache.retrieveById).toHaveBeenCalledWith(userId);
      expect(UsersCache.retrieveStatusById).toHaveBeenCalledWith(userId);
    });
  });

  it('removes aria-describedby attribute from the user link on mouseleave', () => {
    const userLink = document.querySelector(selector);

    userLink.setAttribute('aria-describedby', 'popover');
    triggerEvent('mouseleave', userLink);

    expect(userLink.getAttribute('aria-describedby')).toBe(null);
  });
});
