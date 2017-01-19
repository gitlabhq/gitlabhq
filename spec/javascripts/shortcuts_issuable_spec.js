/* eslint-disable space-before-function-paren, no-return-assign, no-var, quotes */
/* global ShortcutsIssuable */

/*= require copy_as_gfm */
/*= require shortcuts_issuable */

(function() {
  describe('ShortcutsIssuable', function() {
    var fixtureName = 'issues/open-issue.html.raw';
    preloadFixtures(fixtureName);
    beforeEach(function() {
      loadFixtures(fixtureName);
      document.querySelector('.js-new-note-form').classList.add('js-main-target-form');
      return this.shortcut = new ShortcutsIssuable();
    });
    return describe('#replyWithSelectedText', function() {
      var stubSelection;
      // Stub window.gl.utils.getSelectedFragment to return a node with the provided HTML.
      stubSelection = function(html) {
        window.gl.utils.getSelectedFragment = function() {
          var node = document.createElement('div');
          node.innerHTML = html;
          return node;
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
          return stubSelection('<p>Selected text.</p>');
        });
        it('leaves existing input intact', function() {
          $(this.selector).val('This text was already here.');
          expect($(this.selector).val()).toBe('This text was already here.');
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe("This text was already here.\n\n> Selected text.\n\n");
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
          stubSelection('<p>This text has been selected.</p>');
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe("> This text has been selected.\n\n");
        });
      });
      return describe('with a multi-line selection', function() {
        return it('quotes the selected lines as a group', function() {
          stubSelection("<p>Selected line one.</p>\n\n<p>Selected line two.</p>\n\n<p>Selected line three.</p>");
          this.shortcut.replyWithSelectedText();
          return expect($(this.selector).val()).toBe("> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n");
        });
      });
    });
  });
}).call(this);
