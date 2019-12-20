import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import axios from '~/lib/utils/axios_utils';
import { getSelector, dismiss, inserted } from '~/feature_highlight/feature_highlight_helper';
import { togglePopover } from '~/shared/popover';

describe('feature highlight helper', () => {
  describe('getSelector', () => {
    it('returns js-feature-highlight selector', () => {
      const highlightId = 'highlightId';

      expect(getSelector(highlightId)).toEqual(
        `.js-feature-highlight[data-highlight=${highlightId}]`,
      );
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

    it('calls persistent dismissal endpoint', done => {
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

  describe('inserted', () => {
    it('registers click event callback', done => {
      const context = {
        getAttribute: () => 'popoverId',
        dataset: {
          highlight: 'some-feature',
        },
      };

      spyOn($.fn, 'on').and.callFake(event => {
        expect(event).toEqual('click');
        done();
      });
      inserted.call(context);
    });
  });
});
