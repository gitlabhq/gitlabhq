
/*= require extensions/array */

(function() {
  describe('Array extensions', function() {
    describe('first', function() {
      return it('returns the first item', function() {
        var arr;
        arr = [0, 1, 2, 3, 4, 5];
        return expect(arr.first()).toBe(0);
      });
    });
    return describe('last', function() {
      return it('returns the last item', function() {
        var arr;
        arr = [0, 1, 2, 3, 4, 5];
        return expect(arr.last()).toBe(5);
      });
    });
  });

}).call(this);
