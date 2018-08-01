import * as textUtils from '~/lib/utils/text_utility';

describe('text_utility', () => {
  describe('addDelimiter', () => {
    it('should add a delimiter to the given string', () => {
      expect(textUtils.addDelimiter('1234')).toEqual('1,234');
      expect(textUtils.addDelimiter('222222')).toEqual('222,222');
    });

    it('should not add a delimiter if string contains no numbers', () => {
      expect(textUtils.addDelimiter('aaaa')).toEqual('aaaa');
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

  describe('humanize', () => {
    it('should remove underscores and uppercase the first letter', () => {
      expect(textUtils.humanize('foo_bar')).toEqual('Foo bar');
    });
  });

  describe('pluralize', () => {
    it('should pluralize given string', () => {
      expect(textUtils.pluralize('test', 2)).toBe('tests');
    });

    it('should pluralize when count is 0', () => {
      expect(textUtils.pluralize('test', 0)).toBe('tests');
    });

    it('should not pluralize when count is 1', () => {
      expect(textUtils.pluralize('test', 1)).toBe('test');
    });
  });

  describe('dasherize', () => {
    it('should replace underscores with dashes', () => {
      expect(textUtils.dasherize('foo_bar_foo')).toEqual('foo-bar-foo');
    });
  });

  describe('slugify', () => {
    it('should remove accents and convert to lower case', () => {
      expect(textUtils.slugify('João')).toEqual('joão');
    });
  });

  describe('stripHtml', () => {
    it('replaces html tag with the default replacement', () => {
      expect(textUtils.stripHtml('This is a text with <p>html</p>.')).toEqual(
        'This is a text with html.',
      );
    });

    it('replaces html tags with the provided replacement', () => {
      expect(textUtils.stripHtml('This is a text with <p>html</p>.', ' ')).toEqual(
        'This is a text with  html .',
      );
    });

    it('passes through with null string input', () => {
      expect(textUtils.stripHtml(null, ' ')).toEqual(null);
    });

    it('passes through with undefined string input', () => {
      expect(textUtils.stripHtml(undefined, ' ')).toEqual(undefined);
    });
  });

  describe('convertToCamelCase', () => {
    it('converts snake_case string to camelCase string', () => {
      expect(textUtils.convertToCamelCase('snake_case')).toBe('snakeCase');
    });
  });

  describe('convertToSentenceCase', () => {
    it('converts Sentence Case to Sentence case', () => {
      expect(textUtils.convertToSentenceCase('Hello World')).toBe('Hello world');
    });
  });

  describe('truncateSha', () => {
    it('shortens SHAs to 8 characters', () => {
      expect(textUtils.truncateSha('verylongsha')).toBe('verylong');
    });

    it('leaves short SHAs as is', () => {
      expect(textUtils.truncateSha('shortsha')).toBe('shortsha');
    });
  });

  describe('splitCamelCase', () => {
    it('separates a PascalCase word to two', () => {
      expect(textUtils.splitCamelCase('HelloWorld')).toBe('Hello World');
    });
  });

  describe('getFirstCharacterCapitalized', () => {
    it('returns the first character captialized, if first character is alphabetic', () => {
      expect(textUtils.getFirstCharacterCapitalized('loremIpsumDolar')).toEqual('L');
      expect(textUtils.getFirstCharacterCapitalized('Sit amit !')).toEqual('S');
    });

    it('returns the first character, if first character is non-alphabetic', () => {
      expect(textUtils.getFirstCharacterCapitalized(' lorem')).toEqual(' ');
      expect(textUtils.getFirstCharacterCapitalized('%#!')).toEqual('%');
    });

    it('returns an empty string, if string is falsey', () => {
      expect(textUtils.getFirstCharacterCapitalized('')).toEqual('');
      expect(textUtils.getFirstCharacterCapitalized(null)).toEqual('');
    });
  });
});
