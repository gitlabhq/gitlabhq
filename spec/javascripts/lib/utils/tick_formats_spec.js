import { dateTickFormat, initDateFormats } from '~/lib/utils/tick_formats';

import { setLanguage } from '../../helpers/locale_helper';

describe('tick formats', () => {
  describe('dateTickFormat', () => {
    beforeAll(() => {
      setLanguage('de');
      initDateFormats();
    });

    afterAll(() => {
      setLanguage(null);
    });

    it('returns year for first of January', () => {
      const tick = dateTickFormat(new Date('2001-01-01'));

      expect(tick).toBe('2001');
    });

    it('returns month for first of February', () => {
      const tick = dateTickFormat(new Date('2001-02-01'));

      expect(tick).toBe('Februar');
    });

    it('returns day and month for second of February', () => {
      const tick = dateTickFormat(new Date('2001-02-02'));

      expect(tick).toBe('2. Feb.');
    });

    it('ignores time', () => {
      const tick = dateTickFormat(new Date('2001-02-02 12:34:56'));

      expect(tick).toBe('2. Feb.');
    });
  });
});
