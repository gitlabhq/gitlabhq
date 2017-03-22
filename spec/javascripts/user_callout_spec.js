import Cookies from 'js-cookie';
import UserCallout from '~/user_callout';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

describe('UserCallout', () => {
  const fixtureName = 'static/user_callout.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(function () {
    loadFixtures(fixtureName);
    this.userCallout = new UserCallout();
    this.closeButton = $('.close-user-callout');
    this.userCalloutBtn = $('.user-callout-btn');
    this.userCalloutContainer = $('.user-callout');
    Cookies.set(USER_CALLOUT_COOKIE, 'false');
  });

  afterEach(function () {
    Cookies.set(USER_CALLOUT_COOKIE, 'false');
  });

  it('shows when cookie is set to false', function () {
    expect(Cookies.get(USER_CALLOUT_COOKIE)).toBeDefined();
    expect(this.userCalloutContainer.is(':visible')).toBe(true);
  });

  it('hides when user clicks on the dismiss-icon', function () {
    this.closeButton.click();
    expect(Cookies.get(USER_CALLOUT_COOKIE)).toBe('true');
  });

  it('hides when user clicks on the "check it out" button', function () {
    this.userCalloutBtn.click();
    expect(Cookies.get(USER_CALLOUT_COOKIE)).toBe('true');
  });
});
