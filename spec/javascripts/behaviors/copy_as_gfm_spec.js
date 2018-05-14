import { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';

describe('CopyAsGFM', () => {
  describe('CopyAsGFM.pasteGFM', () => {
    function callPasteGFM() {
      const e = {
        originalEvent: {
          clipboardData: {
            getData(mimeType) {
              // When GFM code is copied, we put the regular plain text
              // on the clipboard as `text/plain`, and the GFM as `text/x-gfm`.
              // This emulates the behavior of `getData` with that data.
              if (mimeType === 'text/plain') {
                return 'code';
              }
              if (mimeType === 'text/x-gfm') {
                return '`code`';
              }
              return null;
            },
          },
        },
        preventDefault() {},
      };

      CopyAsGFM.pasteGFM(e);
    }

    it('wraps pasted code when not already in code tags', () => {
      spyOn(window.gl.utils, 'insertText').and.callFake((el, textFunc) => {
        const insertedText = textFunc('This is code: ', '');
        expect(insertedText).toEqual('`code`');
      });

      callPasteGFM();
    });

    it('does not wrap pasted code when already in code tags', () => {
      spyOn(window.gl.utils, 'insertText').and.callFake((el, textFunc) => {
        const insertedText = textFunc('This is code: `', '`');
        expect(insertedText).toEqual('code');
      });

      callPasteGFM();
    });
  });
});
