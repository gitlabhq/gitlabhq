/* eslint-disable space-before-function-paren, no-var, one-var, one-var-declaration-per-line, object-shorthand, comma-dangle, no-return-assign, new-cap, max-len */
/* global Dropzone */
/* global Mousetrap */

import ZenMode from '~/zen_mode';

(function() {
  var enterZen, escapeKeydown, exitZen;

  describe('ZenMode', function() {
    var fixtureName = 'issues/open-issue.html.raw';
    preloadFixtures(fixtureName);
    beforeEach(function() {
      loadFixtures(fixtureName);
      spyOn(Dropzone, 'forElement').and.callFake(function() {
        return {
          enable: function() {
            return true;
          }
        };
      // Stub Dropzone.forElement(...).enable()
      });
      this.zen = new ZenMode();
      // Set this manually because we can't actually scroll the window
      return this.zen.scroll_position = 456;
    });
    describe('on enter', function() {
      it('pauses Mousetrap', function() {
        spyOn(Mousetrap, 'pause');
        enterZen();
        return expect(Mousetrap.pause).toHaveBeenCalled();
      });
      return it('removes textarea styling', function() {
        $('.notes-form textarea').attr('style', 'height: 400px');
        enterZen();
        return expect($('.notes-form textarea')).not.toHaveAttr('style');
      });
    });
    describe('in use', function() {
      beforeEach(function() {
        return enterZen();
      });
      return it('exits on Escape', function() {
        escapeKeydown();
        return expect($('.notes-form .zen-backdrop')).not.toHaveClass('fullscreen');
      });
    });
    return describe('on exit', function() {
      beforeEach(function() {
        return enterZen();
      });
      it('unpauses Mousetrap', function() {
        spyOn(Mousetrap, 'unpause');
        exitZen();
        return expect(Mousetrap.unpause).toHaveBeenCalled();
      });
      return it('restores the scroll position', function() {
        spyOn(this.zen, 'scrollTo');
        exitZen();
        return expect(this.zen.scrollTo).toHaveBeenCalled();
      });
    });
  });

  enterZen = function() {
    return $('.notes-form .js-zen-enter').click();
  };

  exitZen = function() {
    return $('.notes-form .js-zen-leave').click();
  };

  escapeKeydown = function() {
    return $('.notes-form textarea').trigger($.Event('keydown', {
      keyCode: 27
    }));
  };
}).call(window);
