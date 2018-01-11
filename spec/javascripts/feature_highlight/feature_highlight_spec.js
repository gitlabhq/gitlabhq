import * as featureHighlightHelper from '~/feature_highlight/feature_highlight_helper';
import * as featureHighlight from '~/feature_highlight/feature_highlight';

describe('feature highlight', () => {
  beforeEach(() => {
    setFixtures(`
      <div>
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled>
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
  });

  describe('setupFeatureHighlightPopover', () => {
    const selector = '.js-feature-highlight[data-highlight=test]';
    beforeEach(() => {
      spyOn(window, 'addEventListener');
      spyOn(window, 'removeEventListener');
      featureHighlight.setupFeatureHighlightPopover('test', 0);
    });

    it('setup popover content', () => {
      const $popoverContent = $('.feature-highlight-popover-content');
      const outerHTML = $popoverContent.prop('outerHTML');

      expect($(selector).data('content')).toEqual(outerHTML);
    });

    it('setup mouseenter', () => {
      const toggleSpy = spyOn(featureHighlightHelper.togglePopover, 'call');
      $(selector).trigger('mouseenter');

      expect(toggleSpy).toHaveBeenCalledWith(jasmine.any(Object), true);
    });

    it('setup debounced mouseleave', (done) => {
      const toggleSpy = spyOn(featureHighlightHelper.togglePopover, 'call');
      $(selector).trigger('mouseleave');

      // Even though we've set the debounce to 0ms, setTimeout is needed for the debounce
      setTimeout(() => {
        expect(toggleSpy).toHaveBeenCalledWith(jasmine.any(Object), false);
        done();
      }, 0);
    });

    it('setup inserted.bs.popover', () => {
      $(selector).trigger('mouseenter');
      const popoverId = $(selector).attr('aria-describedby');
      const spyEvent = spyOnEvent(`#${popoverId} .dismiss-feature-highlight`, 'click');

      $(`#${popoverId} .dismiss-feature-highlight`).click();
      expect(spyEvent).toHaveBeenTriggered();
    });

    it('setup show.bs.popover', () => {
      $(selector).trigger('show.bs.popover');
      expect(window.addEventListener).toHaveBeenCalledWith('scroll', jasmine.any(Function));
    });

    it('setup hide.bs.popover', () => {
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

  describe('findHighestPriorityFeature', () => {
    beforeEach(() => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-high-priority" data-highlight-priority="20" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-low-priority" data-highlight-priority="0" disabled></div>
      `);
    });

    it('should pick the highest priority feature highlight', () => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-high-priority" data-highlight-priority="20" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-low-priority" data-highlight-priority="0" disabled></div>
      `);

      expect($('.js-feature-highlight').length).toBeGreaterThan(1);
      expect(featureHighlight.findHighestPriorityFeature()).toEqual('test-high-priority');
    });

    it('should work when no priority is set', () => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test" disabled></div>
      `);

      expect(featureHighlight.findHighestPriorityFeature()).toEqual('test');
    });

    it('should pick the highest priority feature highlight when some have no priority set', () => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test-no-priority1" disabled></div>
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-no-priority2" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-high-priority" data-highlight-priority="20" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-low-priority" data-highlight-priority="0" disabled></div>
      `);

      expect($('.js-feature-highlight').length).toBeGreaterThan(1);
      expect(featureHighlight.findHighestPriorityFeature()).toEqual('test-high-priority');
    });
  });

  describe('highlightFeatures', () => {
    it('calls setupFeatureHighlightPopover', () => {
      expect(featureHighlight.highlightFeatures()).toEqual('test');
    });
  });
});
