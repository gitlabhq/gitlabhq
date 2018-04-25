import csrf from '~/lib/utils/csrf';

describe('csrf', function () {
  beforeEach(() => {
    this.tokenKey = 'X-CSRF-Token';
    this.token = 'pH1cvjnP9grx2oKlhWEDvUZnJ8x2eXsIs1qzyHkF3DugSG5yTxR76CWeEZRhML2D1IeVB7NEW0t5l/axE4iJpQ==';
  });

  it('returns the correct headerKey', () => {
    expect(csrf.headerKey).toBe(this.tokenKey);
  });

  describe('when csrf token is in the DOM', () => {
    beforeEach(() => {
      setFixtures(`
        <meta name="csrf-token" content="${this.token}">
      `);

      csrf.init();
    });

    it('returns the csrf token', () => {
      expect(csrf.token).toBe(this.token);
    });

    it('returns the csrf headers object', () => {
      expect(csrf.headers[this.tokenKey]).toBe(this.token);
    });
  });

  describe('when csrf token is not in the DOM', () => {
    beforeEach(() => {
      setFixtures(`
        <meta name="some-other-token">
      `);

      csrf.init();
    });

    it('returns null for token', () => {
      expect(csrf.token).toBeNull();
    });

    it('returns empty object for headers', () => {
      expect(typeof csrf.headers).toBe('object');
      expect(Object.keys(csrf.headers).length).toBe(0);
    });
  });
});
