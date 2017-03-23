import Cookies from 'js-cookie';
import UserCallout from '~/user_callout';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

describe('UserCallout', () => {
  const fixtureName = 'static/user_callout.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(function () {
    loadFixtures(fixtureName);
<<<<<<< HEAD
=======
    Cookies.remove(USER_CALLOUT_COOKIE);

>>>>>>> ce/master
    this.userCallout = new UserCallout();
    this.closeButton = $('.close-user-callout');
    this.userCalloutBtn = $('.user-callout-btn');
    this.userCalloutContainer = $('.user-callout');
    Cookies.set(USER_CALLOUT_COOKIE, 'false');
  });

<<<<<<< HEAD
  afterEach(function () {
    Cookies.set(USER_CALLOUT_COOKIE, 'false');
  });

  it('shows when cookie is set to false', function () {
=======
  it('does not show when cookie is set not defined', () => {
    expect(Cookies.get(USER_CALLOUT_COOKIE)).toBeUndefined();
    expect(this.userCalloutContainer.is(':visible')).toBe(true);
  });

  it('shows when cookie is set to false', () => {
    Cookies.set(USER_CALLOUT_COOKIE, 'false');

>>>>>>> ce/master
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
<<<<<<< HEAD
=======
  });
});

describe('UserCallout when cookie is present', function () {
  const fixtureName = 'static/user_callout.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    Cookies.set(USER_CALLOUT_COOKIE, 'true');
    this.userCallout = new UserCallout();
    this.userCalloutContainer = $('.user-callout');
  });

  it('removes the DOM element', () => {
    expect(this.userCalloutContainer.length).toBe(0);
>>>>>>> ce/master
  });
});
