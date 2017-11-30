import * as textUtils from '~/lib/utils/text_utility';

describe('text_utility', () => {
  describe('gl.text.getTextWidth', () => {
    it('returns zero width when no text is passed', () => {
      expect(gl.text.getTextWidth('')).toBe(0);
    });

    it('returns zero width when no text is passed and font is passed', () => {
      expect(gl.text.getTextWidth('', '100px sans-serif')).toBe(0);
    });

    it('returns width when text is passed', () => {
      expect(gl.text.getTextWidth('foo') > 0).toBe(true);
    });

    it('returns bigger width when font is larger', () => {
      const largeFont = gl.text.getTextWidth('foo', '100px sans-serif');
      const regular = gl.text.getTextWidth('foo', '10px sans-serif');
      expect(largeFont > regular).toBe(true);
    });
  });

  describe('gl.text.pluralize', () => {
    it('returns pluralized', () => {
      expect(gl.text.pluralize('test', 2)).toBe('tests');
    });

    it('returns pluralized when count is 0', () => {
      expect(gl.text.pluralize('test', 0)).toBe('tests');
    });

    it('does not return pluralized', () => {
      expect(gl.text.pluralize('test', 1)).toBe('test');
    });
  });

  describe('highCountTrim', () => {
    it('returns 99+ for count >= 100', () => {
      expect(textUtils.highCountTrim(105)).toBe('99+');
      expect(textUtils.highCountTrim(100)).toBe('99+');
    });

    it('returns exact number for count < 100', () => {
      expect(textUtils.highCountTrim(45)).toBe(45);
    });
  });

  describe('capitalizeFirstCharacter', () => {
    it('returns string with first letter capitalized', () => {
      expect(textUtils.capitalizeFirstCharacter('gitlab')).toEqual('Gitlab');
      expect(textUtils.highCountTrim(105)).toBe('99+');
      expect(textUtils.highCountTrim(100)).toBe('99+');
    });
  });

  describe('gl.text.insertText', () => {
    let textArea;

    beforeAll(() => {
      textArea = document.createElement('textarea');
      document.querySelector('body').appendChild(textArea);
      textArea.focus();
    });

    afterAll(() => {
      textArea.parentNode.removeChild(textArea);
    });

    describe('without selection', () => {
      it('inserts the tag on an empty line', () => {
        const initialValue = '';

        textArea.value = initialValue;
        textArea.selectionStart = 0;
        textArea.selectionEnd = 0;

        gl.text.insertText(textArea, textArea.value, '*', null, '', false);

        expect(textArea.value).toEqual(`${initialValue}* `);
      });

      it('inserts the tag on a new line if the current one is not empty', () => {
        const initialValue = 'some text';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        gl.text.insertText(textArea, textArea.value, '*', null, '', false);

        expect(textArea.value).toEqual(`${initialValue}\n* `);
      });

      it('inserts the tag on the same line if the current line only contains spaces', () => {
        const initialValue = '  ';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        gl.text.insertText(textArea, textArea.value, '*', null, '', false);

        expect(textArea.value).toEqual(`${initialValue}* `);
      });

      it('inserts the tag on the same line if the current line only contains tabs', () => {
        const initialValue = '\t\t\t';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        gl.text.insertText(textArea, textArea.value, '*', null, '', false);

        expect(textArea.value).toEqual(`${initialValue}* `);
      });
    });
  });
});
