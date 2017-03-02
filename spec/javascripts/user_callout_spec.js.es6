const UserCallout = require('~/user_callout');

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';
const Cookie = window.Cookies;

describe('UserCallout', function () {
  const fixtureName = 'static/user_callout.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    Cookie.remove(USER_CALLOUT_COOKIE);

    this.userCallout = new UserCallout();
    this.closeButton = $('.close-user-callout');
    this.userCalloutBtn = $('.user-callout-btn');
    this.userCalloutContainer = $('.user-callout');
  });

  it('does not show when cookie is set not defined', () => {
    expect(Cookie.get(USER_CALLOUT_COOKIE)).toBeUndefined();
    expect(this.userCalloutContainer.is(':visible')).toBe(true);
  });

  it('shows when cookie is set to false', () => {
    Cookie.set(USER_CALLOUT_COOKIE, 'false');

    expect(Cookie.get(USER_CALLOUT_COOKIE)).toBeDefined();
    expect(this.userCalloutContainer.is(':visible')).toBe(true);
  });

  it('hides when user clicks on the dismiss-icon', () => {
    this.closeButton.click();
    expect(Cookie.get(USER_CALLOUT_COOKIE)).toBe('true');
  });

  it('hides when user clicks on the "check it out" button', () => {
    this.userCalloutBtn.click();
    expect(Cookie.get(USER_CALLOUT_COOKIE)).toBe('true');
  });
});

describe('UserCallout when cookie is present', function () {
  const fixtureName = 'static/user_callout.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    Cookie.set(USER_CALLOUT_COOKIE, 'true');
    this.userCallout = new UserCallout();
    this.userCalloutContainer = $('.user-callout');
  });

  it('removes the DOM element', () => {
    expect(this.userCalloutContainer.length).toBe(0);
  });
});
