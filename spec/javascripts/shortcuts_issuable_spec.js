/* eslint-disable space-before-function-paren, no-return-assign, no-var, quotes */
/* global ShortcutsIssuable */

require('~/copy_as_gfm');
require('~/shortcuts_issuable');

(function() {
  describe('ShortcutsIssuable', function() {
    var fixtureName = 'issues/open-issue.html.raw';
    preloadFixtures(fixtureName);
    beforeEach(function() {
      loadFixtures(fixtureName);
      document.querySelector('.js-new-note-form').classList.add('js-main-target-form');
      this.shortcut = new ShortcutsIssuable();
    });
    describe('#replyWithSelectedText', function() {
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
        this.selector = 'form.js-main-target-form textarea#note_note';
      });
      describe('with empty selection', function() {
        it('does not return an error', function() {
          this.shortcut.replyWithSelectedText();
          expect($(this.selector).val()).toBe('');
        });
        it('triggers `input`', function() {
          var focused = false;
          $(this.selector).on('focus', function() {
            focused = true;
          });
          this.shortcut.replyWithSelectedText();
          expect(focused).toBe(true);
        });
      });
      describe('with any selection', function() {
        beforeEach(function() {
          stubSelection('<p>Selected text.</p>');
        });
        it('leaves existing input intact', function() {
          $(this.selector).val('This text was already here.');
          expect($(this.selector).val()).toBe('This text was already here.');
          this.shortcut.replyWithSelectedText();
          expect($(this.selector).val()).toBe("This text was already here.\n\n> Selected text.\n\n");
        });
        it('triggers `input`', function() {
          var triggered = false;
          $(this.selector).on('input', function() {
            triggered = true;
          });
          this.shortcut.replyWithSelectedText();
          expect(triggered).toBe(true);
        });
        it('triggers `focus`', function() {
          this.shortcut.replyWithSelectedText();
          expect(document.activeElement).toBe(document.querySelector(this.selector));
        });
      });
      describe('with a one-line selection', function() {
        it('quotes the selection', function() {
          stubSelection('<p>This text has been selected.</p>');
          this.shortcut.replyWithSelectedText();
          expect($(this.selector).val()).toBe("> This text has been selected.\n\n");
        });
      });
      describe('with a multi-line selection', function() {
        it('quotes the selected lines as a group', function() {
          stubSelection("<p>Selected line one.</p>\n\n<p>Selected line two.</p>\n\n<p>Selected line three.</p>");
          this.shortcut.replyWithSelectedText();
          expect($(this.selector).val()).toBe("> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n");
        });
      });
    });
  });
}).call(window);
