/* eslint-disable space-before-function-paren, no-return-assign, no-undef, no-var, quotes, padded-blocks, max-len */

/*= require shortcuts_issuable */

(function() {
  describe('ShortcutsIssuable', function() {
    fixture.preload('issuable.html');
    beforeEach(function() {
      fixture.load('issuable.html');
      return this.shortcut = new ShortcutsIssuable();
    });
    return describe('#replyWithSelectedText', function() {
      var stubSelection;
      // Stub window.getSelection to return the provided String.
      stubSelection = function(text) {
        return window.getSelection = function() {
          return text;
        };
      };
      beforeEach(function() {
        return this.selector = 'form.js-main-target-form textarea#note_note';
      });
      describe('with empty selection', function() {
        return it('does nothing', function() {
          stubSelection('');
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe('');
        });
      });
      describe('with any selection', function() {
        beforeEach(function() {
          return stubSelection('Selected text.');
        });
        it('leaves existing input intact', function() {
          $(this.selector).val('This text was already here.');
          expect($(this.selector).val()).toBe('This text was already here.');
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe("This text was already here.\n> Selected text.\n\n");
        });
        it('triggers `input`', function() {
          var triggered;
          triggered = false;
          $(this.selector).on('input', function() {
            return triggered = true;
          });
          this.shortcut.replyWithSelectedText();
          return expect(triggered).toBe(true);
        });
        return it('triggers `focus`', function() {
          var focused;
          focused = false;
          $(this.selector).on('focus', function() {
            return focused = true;
          });
          this.shortcut.replyWithSelectedText();
          return expect(focused).toBe(true);
        });
      });
      describe('with a one-line selection', function() {
        return it('quotes the selection', function() {
          stubSelection('This text has been selected.');
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe("> This text has been selected.\n\n");
        });
      });
      return describe('with a multi-line selection', function() {
        return it('quotes the selected lines as a group', function() {
          stubSelection("Selected line one.\n\nSelected line two.\nSelected line three.\n");
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe("> Selected line one.\n> Selected line two.\n> Selected line three.\n\n");
        });
      });
    });
  });

}).call(this);
