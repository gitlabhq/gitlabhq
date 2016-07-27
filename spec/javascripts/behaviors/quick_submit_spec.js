
/*= require behaviors/quick_submit */

(function() {
  describe('Quick Submit behavior', function() {
    var keydownEvent;
    fixture.preload('behaviors/quick_submit.html');
    beforeEach(function() {
      fixture.load('behaviors/quick_submit.html');
      $('form').submit(function(e) {
        // Prevent a form submit from moving us off the testing page
        return e.preventDefault();
      });
      return this.spies = {
        submit: spyOnEvent('form', 'submit')
      };
    });
    it('does not respond to other keyCodes', function() {
      $('input.quick-submit-input').trigger(keydownEvent({
        keyCode: 32
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
    it('does not respond to Enter alone', function() {
      $('input.quick-submit-input').trigger(keydownEvent({
        ctrlKey: false,
        metaKey: false
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
    it('does not respond to repeated events', function() {
      $('input.quick-submit-input').trigger(keydownEvent({
        repeat: true
      }));
      return expect(this.spies.submit).not.toHaveBeenTriggered();
    });
    it('disables submit buttons', function() {
      $('textarea').trigger(keydownEvent());
      expect($('input[type=submit]')).toBeDisabled();
      return expect($('button[type=submit]')).toBeDisabled();
    });
    // We cannot stub `navigator.userAgent` for CI's `rake teaspoon` task, so we'll
    // only run the tests that apply to the current platform
    if (navigator.userAgent.match(/Macintosh/)) {
      it('responds to Meta+Enter', function() {
        $('input.quick-submit-input').trigger(keydownEvent());
        return expect(this.spies.submit).toHaveBeenTriggered();
      });
      it('excludes other modifier keys', function() {
        $('input.quick-submit-input').trigger(keydownEvent({
          altKey: true
        }));
        $('input.quick-submit-input').trigger(keydownEvent({
          ctrlKey: true
        }));
        $('input.quick-submit-input').trigger(keydownEvent({
          shiftKey: true
        }));
        return expect(this.spies.submit).not.toHaveBeenTriggered();
      });
    } else {
      it('responds to Ctrl+Enter', function() {
        $('input.quick-submit-input').trigger(keydownEvent());
        return expect(this.spies.submit).toHaveBeenTriggered();
      });
      it('excludes other modifier keys', function() {
        $('input.quick-submit-input').trigger(keydownEvent({
          altKey: true
        }));
        $('input.quick-submit-input').trigger(keydownEvent({
          metaKey: true
        }));
        $('input.quick-submit-input').trigger(keydownEvent({
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

}).call(this);
