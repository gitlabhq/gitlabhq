import $ from 'jquery';
import initCopyAsGFM from '~/behaviors/markdown/copy_as_gfm';
import ShortcutsIssuable from '~/shortcuts_issuable';

initCopyAsGFM();

describe('ShortcutsIssuable', () => {
  const fixtureName = 'merge_requests/diff_comment.html.raw';
  preloadFixtures(fixtureName);
  beforeEach(() => {
    loadFixtures(fixtureName);
    document.querySelector('.js-new-note-form').classList.add('js-main-target-form');
    this.shortcut = new ShortcutsIssuable(true);
  });
  describe('replyWithSelectedText', () => {
    // Stub window.gl.utils.getSelectedFragment to return a node with the provided HTML.
    const stubSelection = (html) => {
      window.gl.utils.getSelectedFragment = () => {
        const node = document.createElement('div');
        node.innerHTML = html;
        return node;
      };
    };
    beforeEach(() => {
      this.selector = '.js-main-target-form #note_note';
    });
    describe('with empty selection', () => {
      it('does not return an error', () => {
        this.shortcut.replyWithSelectedText(true);
        expect($(this.selector).val()).toBe('');
      });
      it('triggers `focus`', () => {
        this.shortcut.replyWithSelectedText(true);
        expect(document.activeElement).toBe(document.querySelector(this.selector));
      });
    });
    describe('with any selection', () => {
      beforeEach(() => {
        stubSelection('<p>Selected text.</p>');
      });
      it('leaves existing input intact', () => {
        $(this.selector).val('This text was already here.');
        expect($(this.selector).val()).toBe('This text was already here.');
        this.shortcut.replyWithSelectedText(true);
        expect($(this.selector).val()).toBe('This text was already here.\n\n> Selected text.\n\n');
      });
      it('triggers `input`', () => {
        let triggered = false;
        $(this.selector).on('input', () => {
          triggered = true;
        });
        this.shortcut.replyWithSelectedText(true);
        expect(triggered).toBe(true);
      });
      it('triggers `focus`', () => {
        this.shortcut.replyWithSelectedText(true);
        expect(document.activeElement).toBe(document.querySelector(this.selector));
      });
    });
    describe('with a one-line selection', () => {
      it('quotes the selection', () => {
        stubSelection('<p>This text has been selected.</p>');
        this.shortcut.replyWithSelectedText(true);
        expect($(this.selector).val()).toBe('> This text has been selected.\n\n');
      });
    });
    describe('with a multi-line selection', () => {
      it('quotes the selected lines as a group', () => {
        stubSelection('<p>Selected line one.</p>\n\n<p>Selected line two.</p>\n\n<p>Selected line three.</p>');
        this.shortcut.replyWithSelectedText(true);
        expect($(this.selector).val()).toBe('> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n');
      });
    });
  });
});
