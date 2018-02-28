import Cookies from 'js-cookie';
import {
  getCookieName,
  getSelector,
  showPopover,
  hidePopover,
  dismiss,
  mouseleave,
  mouseenter,
  setupDismissButton,
} from '~/feature_highlight/feature_highlight_helper';

describe('feature highlight helper', () => {
  describe('getCookieName', () => {
    it('returns `feature-highlighted-` prefix', () => {
      const cookieId = 'cookieId';
      expect(getCookieName(cookieId)).toEqual(`feature-highlighted-${cookieId}`);
    });
  });

  describe('getSelector', () => {
    it('returns js-feature-highlight selector', () => {
      const highlightId = 'highlightId';
      expect(getSelector(highlightId)).toEqual(`.js-feature-highlight[data-highlight=${highlightId}]`);
    });
  });

  describe('showPopover', () => {
    it('returns true when popover is shown', () => {
      const context = {
        hasClass: () => false,
        popover: () => {},
        addClass: () => {},
      };

      expect(showPopover.call(context)).toEqual(true);
    });

    it('returns false when popover is already shown', () => {
      const context = {
        hasClass: () => true,
      };

      expect(showPopover.call(context)).toEqual(false);
    });

    it('shows popover', (done) => {
      const context = {
        hasClass: () => false,
        popover: () => {},
        addClass: () => {},
      };

      spyOn(context, 'popover').and.callFake((method) => {
        expect(method).toEqual('show');
        done();
      });

      showPopover.call(context);
    });

    it('adds disable-animation and js-popover-show class', (done) => {
      const context = {
        hasClass: () => false,
        popover: () => {},
        addClass: () => {},
      };

      spyOn(context, 'addClass').and.callFake((classNames) => {
        expect(classNames).toEqual('disable-animation js-popover-show');
        done();
      });

      showPopover.call(context);
    });
  });

  describe('hidePopover', () => {
    it('returns true when popover is hidden', () => {
      const context = {
        hasClass: () => true,
        popover: () => {},
        removeClass: () => {},
      };

      expect(hidePopover.call(context)).toEqual(true);
    });

    it('returns false when popover is already hidden', () => {
      const context = {
        hasClass: () => false,
      };

      expect(hidePopover.call(context)).toEqual(false);
    });

    it('hides popover', (done) => {
      const context = {
        hasClass: () => true,
        popover: () => {},
        removeClass: () => {},
      };

      spyOn(context, 'popover').and.callFake((method) => {
        expect(method).toEqual('hide');
        done();
      });

      hidePopover.call(context);
    });

    it('removes disable-animation and js-popover-show class', (done) => {
      const context = {
        hasClass: () => true,
        popover: () => {},
        removeClass: () => {},
      };

      spyOn(context, 'removeClass').and.callFake((classNames) => {
        expect(classNames).toEqual('disable-animation js-popover-show');
        done();
      });

      hidePopover.call(context);
    });
  });

  describe('dismiss', () => {
    const context = {
      hide: () => {},
    };

    beforeEach(() => {
      spyOn(Cookies, 'set').and.callFake(() => {});
      spyOn(hidePopover, 'call').and.callFake(() => {});
      spyOn(context, 'hide').and.callFake(() => {});
      dismiss.call(context);
    });

    it('sets cookie to true', () => {
      expect(Cookies.set).toHaveBeenCalled();
    });

    it('calls hide popover', () => {
      expect(hidePopover.call).toHaveBeenCalled();
    });

    it('calls hide', () => {
      expect(context.hide).toHaveBeenCalled();
    });
  });

  describe('mouseleave', () => {
    it('calls hide popover if .popover:hover is false', () => {
      const fakeJquery = {
        length: 0,
      };

      spyOn($.fn, 'init').and.callFake(selector => (selector === '.popover:hover' ? fakeJquery : $.fn));
      spyOn(hidePopover, 'call');
      mouseleave();
      expect(hidePopover.call).toHaveBeenCalled();
    });

    it('does not call hide popover if .popover:hover is true', () => {
      const fakeJquery = {
        length: 1,
      };

      spyOn($.fn, 'init').and.callFake(selector => (selector === '.popover:hover' ? fakeJquery : $.fn));
      spyOn(hidePopover, 'call');
      mouseleave();
      expect(hidePopover.call).not.toHaveBeenCalled();
    });
  });

  describe('mouseenter', () => {
    const context = {};

    it('shows popover', () => {
      spyOn(showPopover, 'call').and.returnValue(false);
      mouseenter.call(context);
      expect(showPopover.call).toHaveBeenCalled();
    });

    it('registers mouseleave event if popover is showed', (done) => {
      spyOn(showPopover, 'call').and.returnValue(true);
      spyOn($.fn, 'on').and.callFake((eventName) => {
        expect(eventName).toEqual('mouseleave');
        done();
      });
      mouseenter.call(context);
    });

    it('does not register mouseleave event if popover is not showed', () => {
      spyOn(showPopover, 'call').and.returnValue(false);
      const spy = spyOn($.fn, 'on').and.callFake(() => {});
      mouseenter.call(context);
      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('setupDismissButton', () => {
    it('registers click event callback', (done) => {
      const context = {
        getAttribute: () => 'popoverId',
        dataset: {
          highlight: 'cookieId',
        },
      };

      spyOn($.fn, 'on').and.callFake((event) => {
        expect(event).toEqual('click');
        done();
      });
      setupDismissButton.call(context);
    });
  });
});
