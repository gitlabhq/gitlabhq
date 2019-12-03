import initUserPopovers from '~/user_popovers';
import UsersCache from '~/lib/utils/users_cache';

describe('User Popovers', () => {
  const fixtureTemplate = 'merge_requests/diff_comment.html';
  preloadFixtures(fixtureTemplate);

  const selector = '.js-user-link';

  const dummyUser = { name: 'root' };
  const dummyUserStatus = { message: 'active' };

  const triggerEvent = (eventName, el) => {
    const event = document.createEvent('MouseEvents');
    event.initMouseEvent(eventName, true, true, window);

    el.dispatchEvent(event);
  };

  beforeEach(() => {
    loadFixtures(fixtureTemplate);

    const usersCacheSpy = () => Promise.resolve(dummyUser);
    spyOn(UsersCache, 'retrieveById').and.callFake(userId => usersCacheSpy(userId));

    const userStatusCacheSpy = () => Promise.resolve(dummyUserStatus);
    spyOn(UsersCache, 'retrieveStatusById').and.callFake(userId => userStatusCacheSpy(userId));

    initUserPopovers(document.querySelectorAll('.js-user-link'));
  });

  it('Should Show+Hide Popover on mouseenter and mouseleave', done => {
    const targetLink = document.querySelector(selector);
    const { userId } = targetLink.dataset;
    triggerEvent('mouseenter', targetLink);

    setTimeout(() => {
      const shownPopover = document.querySelector('.popover');

      expect(shownPopover).not.toBeNull();
      expect(targetLink.getAttribute('aria-describedby')).not.toBeNull();

      expect(shownPopover.innerHTML).toContain(dummyUser.name);
      expect(UsersCache.retrieveById).toHaveBeenCalledWith(userId.toString());

      triggerEvent('mouseleave', targetLink);

      setTimeout(() => {
        // After Mouse leave it should be hidden now
        expect(document.querySelector('.popover')).toBeNull();
        expect(targetLink.getAttribute('aria-describedby')).toBeNull();
        done();
      });
    }, 210); // We need to wait until the 200ms mouseover delay is over, only then the popover will be visible
  });

  it('Should Not show a popover on short mouse over', done => {
    const targetLink = document.querySelector(selector);
    const { userId } = targetLink.dataset;
    triggerEvent('mouseenter', targetLink);

    setTimeout(() => {
      expect(document.querySelector('.popover')).toBeNull();
      expect(UsersCache.retrieveById).not.toHaveBeenCalledWith(userId.toString());

      triggerEvent('mouseleave', targetLink);

      done();
    });
  });
});
