import $ from 'jquery';
import * as featureHighlight from '~/feature_highlight/feature_highlight';
import * as popover from '~/shared/popover';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

describe('feature highlight', () => {
  beforeEach(() => {
    setFixtures(`
      <div>
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" data-dismiss-endpoint="/test" disabled>
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
    let mock;
    const selector = '.js-feature-highlight[data-highlight=test]';

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet('/test').reply(200);
      spyOn(window, 'addEventListener');
      featureHighlight.setupFeatureHighlightPopover('test', 0);
    });

    afterEach(() => {
      mock.restore();
    });

    it('setup popover content', () => {
      const $popoverContent = $('.feature-highlight-popover-content');
      const outerHTML = $popoverContent.prop('outerHTML');

      expect($(selector).data('content')).toEqual(outerHTML);
    });

    it('setup mouseenter', () => {
      const toggleSpy = spyOn(popover.togglePopover, 'call');
      $(selector).trigger('mouseenter');

      expect(toggleSpy).toHaveBeenCalledWith(jasmine.any(Object), true);
    });

    it('setup debounced mouseleave', (done) => {
      const toggleSpy = spyOn(popover.togglePopover, 'call');
      $(selector).trigger('mouseleave');

      // Even though we've set the debounce to 0ms, setTimeout is needed for the debounce
      setTimeout(() => {
        expect(toggleSpy).toHaveBeenCalledWith(jasmine.any(Object), false);
        done();
      }, 0);
    });

    it('setup show.bs.popover', () => {
      $(selector).trigger('show.bs.popover');
      expect(window.addEventListener).toHaveBeenCalledWith('scroll', jasmine.any(Function), { once: true });
    });

    it('removes disabled attribute', () => {
      expect($('.js-feature-highlight').is(':disabled')).toEqual(false);
    });

    it('displays popover', () => {
      expect(document.querySelector(selector).getAttribute('aria-describedby')).toBeFalsy();
      $(selector).trigger('mouseenter');
      expect(document.querySelector(selector).getAttribute('aria-describedby')).toBeTruthy();
    });

    it('toggles when clicked', () => {
      $(selector).trigger('mouseenter');
      const popoverId = $(selector).attr('aria-describedby');
      const toggleSpy = spyOn(popover.togglePopover, 'call');

      $(`#${popoverId} .dismiss-feature-highlight`).click();

      expect(toggleSpy).toHaveBeenCalled();
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
