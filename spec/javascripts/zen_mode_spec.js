/* eslint-disable */

/*= require zen_mode */

(function() {
  var enterZen, escapeKeydown, exitZen;

  describe('ZenMode', function() {
    fixture.preload('zen_mode.html');
    beforeEach(function() {
      fixture.load('zen_mode.html');
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
        $('textarea').attr('style', 'height: 400px');
        enterZen();
        return expect('textarea').not.toHaveAttr('style');
      });
    });
    describe('in use', function() {
      beforeEach(function() {
        return enterZen();
      });
      return it('exits on Escape', function() {
        escapeKeydown();
        return expect($('.zen-backdrop')).not.toHaveClass('fullscreen');
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
    return $('a.js-zen-enter').click();
  };

  exitZen = function() { // Ohmmmmmmm
    return $('a.js-zen-leave').click();
  };

  escapeKeydown = function() {
    return $('textarea').trigger($.Event('keydown', {
      keyCode: 27
    }));
  };

}).call(this);
