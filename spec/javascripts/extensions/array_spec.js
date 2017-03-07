/* eslint-disable space-before-function-paren, no-var */

require('~/extensions/array');

(function() {
  describe('Array extensions', function() {
    describe('first', function() {
      return it('returns the first item', function() {
        var arr;
        arr = [0, 1, 2, 3, 4, 5];
        return expect(arr.first()).toBe(0);
      });
    });
    describe('last', function() {
      return it('returns the last item', function() {
        var arr;
        arr = [0, 1, 2, 3, 4, 5];
        return expect(arr.last()).toBe(5);
      });
    });

    describe('find', function () {
      beforeEach(() => {
        this.arr = [0, 1, 2, 3, 4, 5];
      });

      it('returns the item that first passes the predicate function', () => {
        expect(this.arr.find(item => item === 2)).toBe(2);
      });

      it('returns undefined if no items pass the predicate function', () => {
        expect(this.arr.find(item => item === 6)).not.toBeDefined();
      });

      it('error when called on undefined or null', () => {
        expect(Array.prototype.find.bind(undefined, item => item === 1)).toThrow();
        expect(Array.prototype.find.bind(null, item => item === 1)).toThrow();
      });

      it('error when predicate is not a function', () => {
        expect(Array.prototype.find.bind(this.arr, 1)).toThrow();
      });
    });
  });
}).call(window);
