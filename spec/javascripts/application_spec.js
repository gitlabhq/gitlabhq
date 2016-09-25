
/*= require lib/utils/common_utils */

(function() {
  describe('Application', function() {
    return describe('disable buttons', function() {
      fixture.preload('application.html');
      beforeEach(function() {
        return fixture.load('application.html');
      });
      it('should prevent default action for disabled buttons', function() {
        var $button, isClicked;
        gl.utils.preventDisabledButtons();
        isClicked = false;
        $button = $('#test-button');
        expect($button).toExist();
        $button.click(function() {
          return isClicked = true;
        });
        $button.trigger('click');
        return expect(isClicked).toBe(false);
      });

      it('should be on the same page if a disabled link clicked', function() {
        var locationBeforeLinkClick, $link;
        locationBeforeLinkClick = window.location.href;
        gl.utils.preventDisabledButtons();
        $link = $('#test-link');
        expect($link).toExist();
        $link.click();
        return expect(window.location.href).toBe(locationBeforeLinkClick);
      });
    });
  });

}).call(this);
