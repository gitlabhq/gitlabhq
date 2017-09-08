import Cookies from 'js-cookie';
import bp from '~/breakpoints';
import * as featureHighlightHelper from '~/feature_highlight/feature_highlight_helper';
import * as featureHighlight from '~/feature_highlight/feature_highlight';

describe('feature highlight', () => {
  describe('init', () => {
    const highlightOrder = [];

    beforeEach(() => {
      // Check for when highlightFeatures is called
      spyOn(highlightOrder, 'find').and.callFake(() => {});
    });

    it('should not call highlightFeatures when breakpoint is xs', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('xs');

      featureHighlight.init(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).not.toHaveBeenCalled();
    });

    it('should not call highlightFeatures when breakpoint is sm', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('sm');

      featureHighlight.init(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).not.toHaveBeenCalled();
    });

    it('should not call highlightFeatures when breakpoint is md', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('md');

      featureHighlight.init(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).not.toHaveBeenCalled();
    });

    it('should call highlightFeatures when breakpoint is lg', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('lg');

      featureHighlight.init(highlightOrder);
      expect(bp.getBreakpointSize).toHaveBeenCalled();
      expect(highlightOrder.find).toHaveBeenCalled();
    });
  });

  describe('setupPopover', () => {
    const selector = '.js-feature-highlight[data-highlight=test]';
    beforeEach(() => {
      setFixtures(`
        <div>
          <div class="js-feature-highlight" data-highlight="test" disabled>
            Trigger
          </div>
        </div>
        <div class="feature-highlight-popover-content">
          Content
          <div class="dismiss-feature-highlight">
            Dismiss
          </div>
        </div>
      `);
      spyOn(window, 'addEventListener');
      spyOn(window, 'removeEventListener');
      featureHighlight.setupPopover('test', 0);
    });

    it('setups popover content', () => {
      const $popoverContent = $('.feature-highlight-popover-content');
      const outerHTML = $popoverContent.prop('outerHTML');

      expect($(selector).data('content')).toEqual(outerHTML);
    });

    it('setups mouseenter', () => {
      const showSpy = spyOn(featureHighlightHelper.showPopover, 'call');
      $(selector).trigger('mouseenter');

      expect(showSpy).toHaveBeenCalled();
    });

    it('setups debounced mouseleave', (done) => {
      const hideSpy = spyOn(featureHighlightHelper.hidePopover, 'call');
      $(selector).trigger('mouseleave');

      // Even though we've set the debounce to 0ms, setTimeout is needed for the debounce
      setTimeout(() => {
        expect(hideSpy).toHaveBeenCalled();
        done();
      }, 0);
    });

    it('setups inserted.bs.popover', () => {
      $(selector).trigger('mouseenter');
      const popoverId = $(selector).attr('aria-describedby');
      const spyEvent = spyOnEvent(`#${popoverId} .dismiss-feature-highlight`, 'click');

      $(`#${popoverId} .dismiss-feature-highlight`).click();
      expect(spyEvent).toHaveBeenTriggered();
    });

    it('setups show.bs.popover', () => {
      $(selector).trigger('show.bs.popover');
      expect(window.addEventListener).toHaveBeenCalledWith('scroll', jasmine.any(Function));
    });

    it('setups hide.bs.popover', () => {
      $(selector).trigger('hide.bs.popover');
      expect(window.removeEventListener).toHaveBeenCalledWith('scroll', jasmine.any(Function));
    });

    it('removes disabled attribute', () => {
      expect($('.js-feature-highlight').is(':disabled')).toEqual(false);
    });

    it('displays popover', () => {
      expect($(selector).attr('aria-describedby')).toBeFalsy();
      $(selector).trigger('mouseenter');
      expect($(selector).attr('aria-describedby')).toBeTruthy();
    });
  });

  describe('shouldHighlightFeature', () => {
    it('should return false if element is not found', () => {
      spyOn(document, 'querySelector').and.returnValue(null);
      spyOn(Cookies, 'get').and.returnValue(null);

      expect(featureHighlight.shouldHighlightFeature()).toBeFalsy();
    });

    it('should return false if previouslyDismissed', () => {
      spyOn(document, 'querySelector').and.returnValue(document.createElement('div'));
      spyOn(Cookies, 'get').and.returnValue('true');

      expect(featureHighlight.shouldHighlightFeature()).toBeFalsy();
    });

    it('should return true if element is found and not previouslyDismissed', () => {
      spyOn(document, 'querySelector').and.returnValue(document.createElement('div'));
      spyOn(Cookies, 'get').and.returnValue(null);

      expect(featureHighlight.shouldHighlightFeature()).toBeTruthy();
    });
  });

  describe('highlightFeatures', () => {
    it('calls setupPopover if shouldHighlightFeature returns true', () => {
      // Mimic shouldHighlightFeature set to true
      const highlightOrder = ['issue-boards'];
      spyOn(highlightOrder, 'find').and.returnValue(highlightOrder[0]);

      expect(featureHighlight.highlightFeatures(highlightOrder)).toEqual(true);
    });

    it('does not call setupPopover if shouldHighlightFeature returns false', () => {
      // Mimic shouldHighlightFeature set to false
      const highlightOrder = ['issue-boards'];
      spyOn(highlightOrder, 'find').and.returnValue(null);

      expect(featureHighlight.highlightFeatures(highlightOrder)).toEqual(false);
    });
  });
});
