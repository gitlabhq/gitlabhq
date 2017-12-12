import { createDateTimeFormat, languageCode } from '~/locale';

import { setLanguage } from '../helpers/locale_helper';

describe('locale', () => {
  afterEach(() => {
    setLanguage(null);
  });

  describe('languageCode', () => {
    it('parses the lang attribute', () => {
      setLanguage('ja');

      expect(languageCode()).toBe('ja');
    });

    it('falls back to English', () => {
      setLanguage(null);

      expect(languageCode()).toBe('en');
    });
  });

  describe('createDateTimeFormat', () => {
    beforeEach(() => {
      setLanguage('de');
    });

    it('creates an instance of Intl.DateTimeFormat', () => {
      const dateFormat = createDateTimeFormat({ year: 'numeric', month: 'long', day: 'numeric' });

      expect(dateFormat.format(new Date(2015, 6, 3))).toBe('3. Juli 2015');
    });
  });
});
