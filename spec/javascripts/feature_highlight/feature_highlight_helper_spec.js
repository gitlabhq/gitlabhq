import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import {
  getSelector,
  dismiss,
  inserted,
} from '~/feature_highlight/feature_highlight_helper';
import {
  togglePopover,
  mouseleave,
  mouseenter,
} from '~/shared/popover';

import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';

describe('feature highlight helper', () => {
  describe('getSelector', () => {
    it('returns js-feature-highlight selector', () => {
      const highlightId = 'highlightId';
      expect(getSelector(highlightId)).toEqual(`.js-feature-highlight[data-highlight=${highlightId}]`);
    });
  });

  describe('togglePopover', () => {
    describe('togglePopover(true)', () => {
      it('returns true when popover is shown', () => {
        const context = {
          hasClass: () => false,
          popover: () => {},
          toggleClass: () => {},
        };

        expect(togglePopover.call(context, true)).toEqual(true);
      });

      it('returns false when popover is already shown', () => {
        const context = {
          hasClass: () => true,
        };

        expect(togglePopover.call(context, true)).toEqual(false);
      });

      it('shows popover', (done) => {
        const context = {
          hasClass: () => false,
          popover: () => {},
          toggleClass: () => {},
        };

        spyOn(context, 'popover').and.callFake((method) => {
          expect(method).toEqual('show');
          done();
        });

        togglePopover.call(context, true);
      });

      it('adds disable-animation and js-popover-show class', (done) => {
        const context = {
          hasClass: () => false,
          popover: () => {},
          toggleClass: () => {},
        };

        spyOn(context, 'toggleClass').and.callFake((classNames, show) => {
          expect(classNames).toEqual('disable-animation js-popover-show');
          expect(show).toEqual(true);
          done();
        });

        togglePopover.call(context, true);
      });
    });

    describe('togglePopover(false)', () => {
      it('returns true when popover is hidden', () => {
        const context = {
          hasClass: () => true,
          popover: () => {},
          toggleClass: () => {},
        };

        expect(togglePopover.call(context, false)).toEqual(true);
      });

      it('returns false when popover is already hidden', () => {
        const context = {
          hasClass: () => false,
        };

        expect(togglePopover.call(context, false)).toEqual(false);
      });

      it('hides popover', (done) => {
        const context = {
          hasClass: () => true,
          popover: () => {},
          toggleClass: () => {},
        };

        spyOn(context, 'popover').and.callFake((method) => {
          expect(method).toEqual('hide');
          done();
        });

        togglePopover.call(context, false);
      });

      it('removes disable-animation and js-popover-show class', (done) => {
        const context = {
          hasClass: () => true,
          popover: () => {},
          toggleClass: () => {},
        };

        spyOn(context, 'toggleClass').and.callFake((classNames, show) => {
          expect(classNames).toEqual('disable-animation js-popover-show');
          expect(show).toEqual(false);
          done();
        });

        togglePopover.call(context, false);
      });
    });
  });

  describe('dismiss', () => {
    let mock;
    const context = {
      hide: () => {},
      attr: () => '/-/callouts/dismiss',
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);

      spyOn(togglePopover, 'call').and.callFake(() => {});
      spyOn(context, 'hide').and.callFake(() => {});
      dismiss.call(context);
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls persistent dismissal endpoint', (done) => {
      const spy = jasmine.createSpy('dismiss-endpoint-hit');
      mock.onPost('/-/callouts/dismiss').reply(spy);

      getSetTimeoutPromise()
        .then(() => {
          expect(spy).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls hide popover', () => {
      expect(togglePopover.call).toHaveBeenCalledWith(context, false);
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
      spyOn(togglePopover, 'call');
      mouseleave();
      expect(togglePopover.call).toHaveBeenCalledWith(jasmine.any(Object), false);
    });

    it('does not call hide popover if .popover:hover is true', () => {
      const fakeJquery = {
        length: 1,
      };

      spyOn($.fn, 'init').and.callFake(selector => (selector === '.popover:hover' ? fakeJquery : $.fn));
      spyOn(togglePopover, 'call');
      mouseleave();
      expect(togglePopover.call).not.toHaveBeenCalledWith(false);
    });
  });

  describe('mouseenter', () => {
    const context = {};

    it('shows popover', () => {
      spyOn(togglePopover, 'call').and.returnValue(false);
      mouseenter.call(context);
      expect(togglePopover.call).toHaveBeenCalledWith(jasmine.any(Object), true);
    });

    it('registers mouseleave event if popover is showed', (done) => {
      spyOn(togglePopover, 'call').and.returnValue(true);
      spyOn($.fn, 'on').and.callFake((eventName) => {
        expect(eventName).toEqual('mouseleave');
        done();
      });
      mouseenter.call(context);
    });

    it('does not register mouseleave event if popover is not showed', () => {
      spyOn(togglePopover, 'call').and.returnValue(false);
      const spy = spyOn($.fn, 'on').and.callFake(() => {});
      mouseenter.call(context);
      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('inserted', () => {
    it('registers click event callback', (done) => {
      const context = {
        getAttribute: () => 'popoverId',
        dataset: {
          highlight: 'some-feature',
        },
      };

      spyOn($.fn, 'on').and.callFake((event) => {
        expect(event).toEqual('click');
        done();
      });
      inserted.call(context);
    });
  });
});
