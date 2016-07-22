
/*= require line_highlighter */
describe('LineHighlighter', function() {
  var clickLine;
  fixture.preload('line_highlighter.html');
  clickLine = function(number, eventData) {
    var e;
    if (eventData == null) {
      eventData = {};
    }
    if ($.isEmptyObject(eventData)) {
      return $("#L" + number).mousedown().click();
    } else {
      e = $.Event('mousedown', eventData);
      return $("#L" + number).trigger(e).click();
    }
  };
  beforeEach(function() {
    fixture.load('line_highlighter.html');
    this["class"] = new LineHighlighter();
    this.css = this["class"].highlightClass;
    return this.spies = {
      __setLocationHash__: spyOn(this["class"], '__setLocationHash__').and.callFake(function() {})
    };
  });
  describe('behavior', function() {
    it('highlights one line given in the URL hash', function() {
      new LineHighlighter('#L13');
      return expect($('#LC13')).toHaveClass(this.css);
    });
    it('highlights a range of lines given in the URL hash', function() {
      var i, line, results;
      new LineHighlighter('#L5-25');
      expect($("." + this.css).length).toBe(21);
      results = [];
      for (line = i = 5; i <= 25; line = ++i) {
        results.push(expect($("#LC" + line)).toHaveClass(this.css));
      }
      return results;
    });
    it('scrolls to the first highlighted line on initial load', function() {
      var spy;
      spy = spyOn($, 'scrollTo');
      new LineHighlighter('#L5-25');
      return expect(spy).toHaveBeenCalledWith('#L5', jasmine.anything());
    });
    it('discards click events', function() {
      var spy;
      spy = spyOnEvent('a[data-line-number]', 'click');
      clickLine(13);
      return expect(spy).toHaveBeenPrevented();
    });
    return it('handles garbage input from the hash', function() {
      var func;
      func = function() {
        return new LineHighlighter('#blob-content-holder');
      };
      return expect(func).not.toThrow();
    });
  });
  describe('#clickHandler', function() {
    it('discards the mousedown event', function() {
      var spy;
      spy = spyOnEvent('a[data-line-number]', 'mousedown');
      clickLine(13);
      return expect(spy).toHaveBeenPrevented();
    });
    it('handles clicking on a child icon element', function() {
      var spy;
      spy = spyOn(this["class"], 'setHash').and.callThrough();
      $('#L13 i').mousedown().click();
      expect(spy).toHaveBeenCalledWith(13);
      return expect($('#LC13')).toHaveClass(this.css);
    });
    describe('without shiftKey', function() {
      it('highlights one line when clicked', function() {
        clickLine(13);
        return expect($('#LC13')).toHaveClass(this.css);
      });
      it('unhighlights previously highlighted lines', function() {
        clickLine(13);
        clickLine(20);
        expect($('#LC13')).not.toHaveClass(this.css);
        return expect($('#LC20')).toHaveClass(this.css);
      });
      return it('sets the hash', function() {
        var spy;
        spy = spyOn(this["class"], 'setHash').and.callThrough();
        clickLine(13);
        return expect(spy).toHaveBeenCalledWith(13);
      });
    });
    return describe('with shiftKey', function() {
      it('sets the hash', function() {
        var spy;
        spy = spyOn(this["class"], 'setHash').and.callThrough();
        clickLine(13);
        clickLine(20, {
          shiftKey: true
        });
        expect(spy).toHaveBeenCalledWith(13);
        return expect(spy).toHaveBeenCalledWith(13, 20);
      });
      describe('without existing highlight', function() {
        it('highlights the clicked line', function() {
          clickLine(13, {
            shiftKey: true
          });
          expect($('#LC13')).toHaveClass(this.css);
          return expect($("." + this.css).length).toBe(1);
        });
        return it('sets the hash', function() {
          var spy;
          spy = spyOn(this["class"], 'setHash');
          clickLine(13, {
            shiftKey: true
          });
          return expect(spy).toHaveBeenCalledWith(13);
        });
      });
      describe('with existing single-line highlight', function() {
        it('uses existing line as last line when target is lesser', function() {
          var i, line, results;
          clickLine(20);
          clickLine(15, {
            shiftKey: true
          });
          expect($("." + this.css).length).toBe(6);
          results = [];
          for (line = i = 15; i <= 20; line = ++i) {
            results.push(expect($("#LC" + line)).toHaveClass(this.css));
          }
          return results;
        });
        return it('uses existing line as first line when target is greater', function() {
          var i, line, results;
          clickLine(5);
          clickLine(10, {
            shiftKey: true
          });
          expect($("." + this.css).length).toBe(6);
          results = [];
          for (line = i = 5; i <= 10; line = ++i) {
            results.push(expect($("#LC" + line)).toHaveClass(this.css));
          }
          return results;
        });
      });
      return describe('with existing multi-line highlight', function() {
        beforeEach(function() {
          clickLine(10, {
            shiftKey: true
          });
          return clickLine(13, {
            shiftKey: true
          });
        });
        it('uses target as first line when it is less than existing first line', function() {
          var i, line, results;
          clickLine(5, {
            shiftKey: true
          });
          expect($("." + this.css).length).toBe(6);
          results = [];
          for (line = i = 5; i <= 10; line = ++i) {
            results.push(expect($("#LC" + line)).toHaveClass(this.css));
          }
          return results;
        });
        return it('uses target as last line when it is greater than existing first line', function() {
          var i, line, results;
          clickLine(15, {
            shiftKey: true
          });
          expect($("." + this.css).length).toBe(6);
          results = [];
          for (line = i = 10; i <= 15; line = ++i) {
            results.push(expect($("#LC" + line)).toHaveClass(this.css));
          }
          return results;
        });
      });
    });
  });
  describe('#hashToRange', function() {
    beforeEach(function() {
      return this.subject = this["class"].hashToRange;
    });
    it('extracts a single line number from the hash', function() {
      return expect(this.subject('#L5')).toEqual([5, null]);
    });
    it('extracts a range of line numbers from the hash', function() {
      return expect(this.subject('#L5-15')).toEqual([5, 15]);
    });
    return it('returns [null, null] when the hash is not a line number', function() {
      return expect(this.subject('#foo')).toEqual([null, null]);
    });
  });
  describe('#highlightLine', function() {
    beforeEach(function() {
      return this.subject = this["class"].highlightLine;
    });
    it('highlights the specified line', function() {
      this.subject(13);
      return expect($('#LC13')).toHaveClass(this.css);
    });
    return it('accepts a String-based number', function() {
      this.subject('13');
      return expect($('#LC13')).toHaveClass(this.css);
    });
  });
  return describe('#setHash', function() {
    beforeEach(function() {
      return this.subject = this["class"].setHash;
    });
    it('sets the location hash for a single line', function() {
      this.subject(5);
      return expect(this.spies.__setLocationHash__).toHaveBeenCalledWith('#L5');
    });
    return it('sets the location hash for a range', function() {
      this.subject(5, 15);
      return expect(this.spies.__setLocationHash__).toHaveBeenCalledWith('#L5-15');
    });
  });
});
