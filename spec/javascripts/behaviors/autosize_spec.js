/* eslint-disable */

/*= require behaviors/autosize */

(function() {
  describe('Autosize behavior', function() {
    var load;
    beforeEach(function() {
      return fixture.set('<textarea class="js-autosize" style="resize: vertical"></textarea>');
    });
    it('does not overwrite the resize property', function() {
      load();
      return expect($('textarea')).toHaveCss({
        resize: 'vertical'
      });
    });
    return load = function() {
      return $(document).trigger('page:load');
    };
  });

}).call(this);
