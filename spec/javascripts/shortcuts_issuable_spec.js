import $ from 'jquery';
import initCopyAsGFM from '~/behaviors/markdown/copy_as_gfm';
import ShortcutsIssuable from '~/shortcuts_issuable';

initCopyAsGFM();

const FORM_SELECTOR = '.js-main-target-form .js-vue-comment-form';

describe('ShortcutsIssuable', function() {
  const fixtureName = 'snippets/show.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    $('body').append(
      `<div class="js-main-target-form">
        <textare class="js-vue-comment-form"></textare>
      </div>`,
    );
    document.querySelector('.js-new-note-form').classList.add('js-main-target-form');
    this.shortcut = new ShortcutsIssuable(true);
  });

  afterEach(() => {
    $(FORM_SELECTOR).remove();
  });

  describe('replyWithSelectedText', () => {
    // Stub window.gl.utils.getSelectedFragment to return a node with the provided HTML.
    const stubSelection = html => {
      window.gl.utils.getSelectedFragment = () => {
        const node = document.createElement('div');
        node.innerHTML = html;

        return node;
      };
    };
    describe('with empty selection', () => {
      it('does not return an error', () => {
        ShortcutsIssuable.replyWithSelectedText(true);

        expect($(FORM_SELECTOR).val()).toBe('');
      });

      it('triggers `focus`', () => {
        const spy = spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        ShortcutsIssuable.replyWithSelectedText(true);

        expect(spy).toHaveBeenCalled();
      });
    });

    describe('with any selection', () => {
      beforeEach(() => {
        stubSelection('<p>Selected text.</p>');
      });

      it('leaves existing input intact', () => {
        $(FORM_SELECTOR).val('This text was already here.');
        expect($(FORM_SELECTOR).val()).toBe('This text was already here.');

        ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('This text was already here.\n\n> Selected text.\n\n');
      });

      it('triggers `input`', () => {
        let triggered = false;
        $(FORM_SELECTOR).on('input', () => {
          triggered = true;
        });

        ShortcutsIssuable.replyWithSelectedText(true);
        expect(triggered).toBe(true);
      });

      it('triggers `focus`', () => {
        const spy = spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        ShortcutsIssuable.replyWithSelectedText(true);

        expect(spy).toHaveBeenCalled();
      });
    });

    describe('with a one-line selection', () => {
      it('quotes the selection', () => {
        stubSelection('<p>This text has been selected.</p>');
        ShortcutsIssuable.replyWithSelectedText(true);

        expect($(FORM_SELECTOR).val()).toBe('> This text has been selected.\n\n');
      });
    });

    describe('with a multi-line selection', () => {
      it('quotes the selected lines as a group', () => {
        stubSelection(
          '<p>Selected line one.</p>\n<p>Selected line two.</p>\n<p>Selected line three.</p>',
        );
        ShortcutsIssuable.replyWithSelectedText(true);

        expect($(FORM_SELECTOR).val()).toBe(
          '> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n',
        );
      });
    });
  });
});
