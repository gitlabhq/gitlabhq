/* eslint-disable no-else-return, dot-notation, no-return-assign, no-new, no-underscore-dangle */

import $ from 'jquery';
import LineHighlighter from '~/line_highlighter';

describe('LineHighlighter', function() {
  preloadFixtures('static/line_highlighter.html');
  const clickLine = function(number, eventData = {}) {
    if ($.isEmptyObject(eventData)) {
      return $(`#L${number}`).click();
    } else {
      const e = $.Event('click', eventData);
      return $(`#L${number}`).trigger(e);
    }
  };
  beforeEach(function() {
    loadFixtures('static/line_highlighter.html');
    this['class'] = new LineHighlighter();
    this.css = this['class'].highlightLineClass;
    return (this.spies = {
      __setLocationHash__: spyOn(this['class'], '__setLocationHash__').and.callFake(function() {}),
    });
  });

  describe('behavior', function() {
    it('highlights one line given in the URL hash', function() {
      new LineHighlighter({ hash: '#L13' });

      expect($('#LC13')).toHaveClass(this.css);
    });

    it('highlights one line given in the URL hash with given CSS class name', function() {
      const hiliter = new LineHighlighter({ hash: '#L13', highlightLineClass: 'hilite' });

      expect(hiliter.highlightLineClass).toBe('hilite');
      expect($('#LC13')).toHaveClass('hilite');
      expect($('#LC13')).not.toHaveClass('hll');
    });

    it('highlights a range of lines given in the URL hash', function() {
      new LineHighlighter({ hash: '#L5-25' });

      expect($(`.${this.css}`).length).toBe(21);
      for (let line = 5; line <= 25; line += 1) {
        expect($(`#LC${line}`)).toHaveClass(this.css);
      }
    });

    it('scrolls to the first highlighted line on initial load', function() {
      const spy = spyOn($, 'scrollTo');
      new LineHighlighter({ hash: '#L5-25' });

      expect(spy).toHaveBeenCalledWith('#L5', jasmine.anything());
    });

    it('discards click events', function() {
      const spy = spyOnEvent('a[data-line-number]', 'click');
      clickLine(13);

      expect(spy).toHaveBeenPrevented();
    });

    it('handles garbage input from the hash', function() {
      const func = function() {
        return new LineHighlighter({ fileHolderSelector: '#blob-content-holder' });
      };

      expect(func).not.toThrow();
    });
  });

  describe('clickHandler', function() {
    it('handles clicking on a child icon element', function() {
      const spy = spyOn(this['class'], 'setHash').and.callThrough();
      $('#L13 i')
        .mousedown()
        .click();

      expect(spy).toHaveBeenCalledWith(13);
      expect($('#LC13')).toHaveClass(this.css);
    });

    describe('without shiftKey', function() {
      it('highlights one line when clicked', function() {
        clickLine(13);

        expect($('#LC13')).toHaveClass(this.css);
      });

      it('unhighlights previously highlighted lines', function() {
        clickLine(13);
        clickLine(20);

        expect($('#LC13')).not.toHaveClass(this.css);
        expect($('#LC20')).toHaveClass(this.css);
      });

      it('sets the hash', function() {
        const spy = spyOn(this['class'], 'setHash').and.callThrough();
        clickLine(13);

        expect(spy).toHaveBeenCalledWith(13);
      });
    });

    describe('with shiftKey', function() {
      it('sets the hash', function() {
        const spy = spyOn(this['class'], 'setHash').and.callThrough();
        clickLine(13);
        clickLine(20, {
          shiftKey: true,
        });

        expect(spy).toHaveBeenCalledWith(13);
        expect(spy).toHaveBeenCalledWith(13, 20);
      });

      describe('without existing highlight', function() {
        it('highlights the clicked line', function() {
          clickLine(13, {
            shiftKey: true,
          });

          expect($('#LC13')).toHaveClass(this.css);
          expect($(`.${this.css}`).length).toBe(1);
        });

        it('sets the hash', function() {
          const spy = spyOn(this['class'], 'setHash');
          clickLine(13, {
            shiftKey: true,
          });

          expect(spy).toHaveBeenCalledWith(13);
        });
      });

      describe('with existing single-line highlight', function() {
        it('uses existing line as last line when target is lesser', function() {
          clickLine(20);
          clickLine(15, {
            shiftKey: true,
          });

          expect($(`.${this.css}`).length).toBe(6);
          for (let line = 15; line <= 20; line += 1) {
            expect($(`#LC${line}`)).toHaveClass(this.css);
          }
        });

        it('uses existing line as first line when target is greater', function() {
          clickLine(5);
          clickLine(10, {
            shiftKey: true,
          });

          expect($(`.${this.css}`).length).toBe(6);
          for (let line = 5; line <= 10; line += 1) {
            expect($(`#LC${line}`)).toHaveClass(this.css);
          }
        });
      });

      describe('with existing multi-line highlight', function() {
        beforeEach(function() {
          clickLine(10, {
            shiftKey: true,
          });
          clickLine(13, {
            shiftKey: true,
          });
        });

        it('uses target as first line when it is less than existing first line', function() {
          clickLine(5, {
            shiftKey: true,
          });

          expect($(`.${this.css}`).length).toBe(6);
          for (let line = 5; line <= 10; line += 1) {
            expect($(`#LC${line}`)).toHaveClass(this.css);
          }
        });

        it('uses target as last line when it is greater than existing first line', function() {
          clickLine(15, {
            shiftKey: true,
          });

          expect($(`.${this.css}`).length).toBe(6);
          for (let line = 10; line <= 15; line += 1) {
            expect($(`#LC${line}`)).toHaveClass(this.css);
          }
        });
      });
    });
  });

  describe('hashToRange', function() {
    beforeEach(function() {
      this.subject = this['class'].hashToRange;
    });

    it('extracts a single line number from the hash', function() {
      expect(this.subject('#L5')).toEqual([5, null]);
    });

    it('extracts a range of line numbers from the hash', function() {
      expect(this.subject('#L5-15')).toEqual([5, 15]);
    });

    it('returns [null, null] when the hash is not a line number', function() {
      expect(this.subject('#foo')).toEqual([null, null]);
    });
  });

  describe('highlightLine', function() {
    beforeEach(function() {
      this.subject = this['class'].highlightLine;
    });

    it('highlights the specified line', function() {
      this.subject(13);

      expect($('#LC13')).toHaveClass(this.css);
    });

    it('accepts a String-based number', function() {
      this.subject('13');

      expect($('#LC13')).toHaveClass(this.css);
    });
  });

  describe('setHash', function() {
    beforeEach(function() {
      this.subject = this['class'].setHash;
    });

    it('sets the location hash for a single line', function() {
      this.subject(5);

      expect(this.spies.__setLocationHash__).toHaveBeenCalledWith('#L5');
    });

    it('sets the location hash for a range', function() {
      this.subject(5, 15);

      expect(this.spies.__setLocationHash__).toHaveBeenCalledWith('#L5-15');
    });
  });
});
