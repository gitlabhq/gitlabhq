import { insertMarkdownText } from '~/lib/utils/text_markdown';

describe('init markdown', () => {
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

      insertMarkdownText(textArea, textArea.value, '*', null, '', false);

      expect(textArea.value).toEqual(`${initialValue}* `);
    });

    it('inserts the tag on a new line if the current one is not empty', () => {
      const initialValue = 'some text';

      textArea.value = initialValue;
      textArea.setSelectionRange(initialValue.length, initialValue.length);

      insertMarkdownText(textArea, textArea.value, '*', null, '', false);

      expect(textArea.value).toEqual(`${initialValue}\n* `);
    });

    it('inserts the tag on the same line if the current line only contains spaces', () => {
      const initialValue = '  ';

      textArea.value = initialValue;
      textArea.setSelectionRange(initialValue.length, initialValue.length);

      insertMarkdownText(textArea, textArea.value, '*', null, '', false);

      expect(textArea.value).toEqual(`${initialValue}* `);
    });

    it('inserts the tag on the same line if the current line only contains tabs', () => {
      const initialValue = '\t\t\t';

      textArea.value = initialValue;
      textArea.setSelectionRange(initialValue.length, initialValue.length);

      insertMarkdownText(textArea, textArea.value, '*', null, '', false);

      expect(textArea.value).toEqual(`${initialValue}* `);
    });
  });
});
