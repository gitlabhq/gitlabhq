import Cookies from 'js-cookie';
import UserCallout from '~/user_callout';

const USER_CALLOUT_COOKIE = 'user_callout_dismissed';

describe('UserCallout', function () {
  const fixtureName = 'dashboard/user-callout.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    Cookies.remove(USER_CALLOUT_COOKIE);

    this.userCallout = new UserCallout();
    this.closeButton = $('.js-close-callout.close');
    this.userCalloutBtn = $('.js-close-callout:not(.close)');
  });

  it('hides when user clicks on the dismiss-icon', (done) => {
    this.closeButton.click();
    expect(Cookies.get(USER_CALLOUT_COOKIE)).toBe('true');

    setTimeout(() => {
      expect(
        document.querySelector('.user-callout'),
      ).toBeNull();

      done();
    });
  });

  it('hides when user clicks on the "check it out" button', () => {
    this.userCalloutBtn.click();
    expect(Cookies.get(USER_CALLOUT_COOKIE)).toBe('true');
  });

  describe('Sets cookie with setCalloutPerProject', () => {
    beforeEach(() => {
      spyOn(Cookies, 'set').and.callFake(() => {});
      document.querySelector('.user-callout').setAttribute('data-project-path', 'foo/bar');
      this.userCallout = new UserCallout({ setCalloutPerProject: true });
    });

    it('sets a cookie when the user clicks the close button', () => {
      this.userCalloutBtn.click();
      expect(Cookies.set).toHaveBeenCalledWith('user_callout_dismissed', 'true', Object({ expires: 365, path: 'foo/bar' }));
    });
  });
});
