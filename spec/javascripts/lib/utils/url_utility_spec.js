import { webIDEUrl, mergeUrlParams } from '~/lib/utils/url_utility';

describe('URL utility', () => {
  describe('webIDEUrl', () => {
    afterEach(() => {
      gon.relative_url_root = '';
    });

    describe('without relative_url_root', () => {
      it('returns IDE path with route', () => {
        expect(webIDEUrl('/gitlab-org/gitlab-ce/merge_requests/1')).toBe(
          '/-/ide/project/gitlab-org/gitlab-ce/merge_requests/1',
        );
      });
    });

    describe('with relative_url_root', () => {
      beforeEach(() => {
        gon.relative_url_root = '/gitlab';
      });

      it('returns IDE path with route', () => {
        expect(webIDEUrl('/gitlab/gitlab-org/gitlab-ce/merge_requests/1')).toBe(
          '/gitlab/-/ide/project/gitlab-org/gitlab-ce/merge_requests/1',
        );
      });
    });
  });

  describe('mergeUrlParams', () => {
    it('adds w', () => {
      expect(mergeUrlParams({ w: 1 }, '#frag')).toBe('?w=1#frag');
      expect(mergeUrlParams({ w: 1 }, '/path#frag')).toBe('/path?w=1#frag');
      expect(mergeUrlParams({ w: 1 }, 'https://host/path')).toBe('https://host/path?w=1');
      expect(mergeUrlParams({ w: 1 }, 'https://host/path#frag')).toBe('https://host/path?w=1#frag');
      expect(mergeUrlParams({ w: 1 }, 'https://h/p?k1=v1#frag')).toBe('https://h/p?k1=v1&w=1#frag');
    });

    it('updates w', () => {
      expect(mergeUrlParams({ w: 1 }, '?k1=v1&w=0#frag')).toBe('?k1=v1&w=1#frag');
    });

    it('adds multiple params', () => {
      expect(mergeUrlParams({ a: 1, b: 2, c: 3 }, '#frag')).toBe('?a=1&b=2&c=3#frag');
    });

    it('adds and updates encoded params', () => {
      expect(mergeUrlParams({ a: '&', q: '?' }, '?a=%23#frag')).toBe('?a=%26&q=%3F#frag');
    });
  });
});
