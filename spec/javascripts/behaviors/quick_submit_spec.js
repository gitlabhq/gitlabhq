/* eslint-disable space-before-function-paren, no-var, no-return-assign, comma-dangle, jasmine/no-spec-dupes, new-cap, max-len */

require('~/behaviors/quick_submit');

(function() {
  describe('Quick Submit behavior', function() {
    var keydownEvent;
    preloadFixtures('issues/open-issue.html.raw');
    beforeEach(function() {
      loadFixtures('issues/open-issue.html.raw');
      $('form').submit(function(e) {
        // Prevent a form submit from moving us off the testing page
        return e.preventDefault();
      });
      this.spies = {
        submit: spyOnEvent('form', 'submit')
      };

      this.textarea = $('.js-quick-submit textarea').first();
    });
    it('does not respond to other keyCodes', function() {
      this.textarea.trigger(keydownEvent({
        keyCode: 32
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
    it('does not respond to Enter alone', function() {
      this.textarea.trigger(keydownEvent({
        ctrlKey: false,
        metaKey: false
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
    it('does not respond to repeated events', function() {
      this.textarea.trigger(keydownEvent({
        repeat: true
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
    it('disables input of type submit', function() {
      const submitButton = $('.js-quick-submit input[type=submit]');
      this.textarea.trigger(keydownEvent());
      expect(submitButton).toBeDisabled();
    });
    it('disables button of type submit', function() {
      // button doesn't exist in fixture, add it manually
      const submitButton = $('<button type="submit">Submit it</button>');
      submitButton.insertAfter(this.textarea);

      this.textarea.trigger(keydownEvent());
      expect(submitButton).toBeDisabled();
    });
    // We cannot stub `navigator.userAgent` for CI's `rake karma` task, so we'll
    // only run the tests that apply to the current platform
    if (navigator.userAgent.match(/Macintosh/)) {
      it('responds to Meta+Enter', function() {
        this.textarea.trigger(keydownEvent());
        return expect(this.spies.submit).toHaveBeenTriggered();
      });
      it('excludes other modifier keys', function() {
        this.textarea.trigger(keydownEvent({
          altKey: true
        }));
        this.textarea.trigger(keydownEvent({
          ctrlKey: true
        }));
        this.textarea.trigger(keydownEvent({
          shiftKey: true
        }));
        return expect(this.spies.submit).not.toHaveBeenTriggered();
      });
    } else {
      it('responds to Ctrl+Enter', function() {
        this.textarea.trigger(keydownEvent());
        return expect(this.spies.submit).toHaveBeenTriggered();
      });
      it('excludes other modifier keys', function() {
        this.textarea.trigger(keydownEvent({
          altKey: true
        }));
        this.textarea.trigger(keydownEvent({
          metaKey: true
        }));
        this.textarea.trigger(keydownEvent({
          shiftKey: true
        }));
        return expect(this.spies.submit).not.toHaveBeenTriggered();
      });
    }
    return keydownEvent = function(options) {
      var defaults;
      if (navigator.userAgent.match(/Macintosh/)) {
        defaults = {
          keyCode: 13,
          metaKey: true
        };
      } else {
        defaults = {
          keyCode: 13,
          ctrlKey: true
        };
      }
      return $.Event('keydown', $.extend({}, defaults, options));
    };
  });
}).call(window);
