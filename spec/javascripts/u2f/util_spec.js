import { canInjectU2fApi } from '~/u2f/util';

describe('U2F Utils', () => {
  describe('canInjectU2fApi', () => {
    it('returns false for Chrome < 41', () => {
      const userAgent = 'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.28 Safari/537.36';
      expect(canInjectU2fApi(userAgent)).toBe(false);
    });

    it('returns true for Chrome >= 41', () => {
      const userAgent = 'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36';
      expect(canInjectU2fApi(userAgent)).toBe(true);
    });

    it('returns false for Opera < 40', () => {
      const userAgent = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36 OPR/32.0.1948.25';
      expect(canInjectU2fApi(userAgent)).toBe(false);
    });

    it('returns true for Opera >= 40', () => {
      const userAgent = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36 OPR/43.0.2442.991';
      expect(canInjectU2fApi(userAgent)).toBe(true);
    });

    it('returns false for Safari', () => {
      const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4';
      expect(canInjectU2fApi(userAgent)).toBe(false);
    });

    it('returns false for Chrome on Android', () => {
      const userAgent = 'Mozilla/5.0 (Linux; Android 7.0; VS988 Build/NRD90U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3145.0 Mobile Safari/537.36';
      expect(canInjectU2fApi(userAgent)).toBe(false);
    });

    it('returns false for Chrome on iOS', () => {
      const userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1';
      expect(canInjectU2fApi(userAgent)).toBe(false);
    });

    it('returns false for Safari on iOS', () => {
      const userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A356 Safari/604.1';
      expect(canInjectU2fApi(userAgent)).toBe(false);
    });
  });
});
