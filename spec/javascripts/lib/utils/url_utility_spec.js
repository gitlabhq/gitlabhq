import * as urlUtils from '~/lib/utils/url_utility';

describe('URL utility', () => {
  describe('webIDEUrl', () => {
    afterEach(() => {
      gon.relative_url_root = '';
    });

    describe('without relative_url_root', () => {
      it('returns IDE path with route', () => {
        expect(urlUtils.webIDEUrl('/gitlab-org/gitlab-ce/merge_requests/1')).toBe(
          '/-/ide/project/gitlab-org/gitlab-ce/merge_requests/1',
        );
      });
    });

    describe('with relative_url_root', () => {
      beforeEach(() => {
        gon.relative_url_root = '/gitlab';
      });

      it('returns IDE path with route', () => {
        expect(urlUtils.webIDEUrl('/gitlab/gitlab-org/gitlab-ce/merge_requests/1')).toBe(
          '/gitlab/-/ide/project/gitlab-org/gitlab-ce/merge_requests/1',
        );
      });
    });
  });

  describe('mergeUrlParams', () => {
    it('adds w', () => {
      expect(urlUtils.mergeUrlParams({ w: 1 }, '#frag')).toBe('?w=1#frag');
      expect(urlUtils.mergeUrlParams({ w: 1 }, '/path#frag')).toBe('/path?w=1#frag');
      expect(urlUtils.mergeUrlParams({ w: 1 }, 'https://host/path')).toBe('https://host/path?w=1');
      expect(urlUtils.mergeUrlParams({ w: 1 }, 'https://host/path#frag')).toBe(
        'https://host/path?w=1#frag',
      );

      expect(urlUtils.mergeUrlParams({ w: 1 }, 'https://h/p?k1=v1#frag')).toBe(
        'https://h/p?k1=v1&w=1#frag',
      );
    });

    it('updates w', () => {
      expect(urlUtils.mergeUrlParams({ w: 1 }, '?k1=v1&w=0#frag')).toBe('?k1=v1&w=1#frag');
    });

    it('adds multiple params', () => {
      expect(urlUtils.mergeUrlParams({ a: 1, b: 2, c: 3 }, '#frag')).toBe('?a=1&b=2&c=3#frag');
    });

    it('adds and updates encoded params', () => {
      expect(urlUtils.mergeUrlParams({ a: '&', q: '?' }, '?a=%23#frag')).toBe('?a=%26&q=%3F#frag');
    });
  });

  describe('removeParams', () => {
    describe('when url is passed', () => {
      it('removes query param with encoded ampersand', () => {
        const url = urlUtils.removeParams(['filter'], '/mail?filter=n%3Djoe%26l%3Dhome');

        expect(url).toBe('/mail');
      });

      it('should remove param when url has no other params', () => {
        const url = urlUtils.removeParams(['size'], '/feature/home?size=5');

        expect(url).toBe('/feature/home');
      });

      it('should remove param when url has other params', () => {
        const url = urlUtils.removeParams(['size'], '/feature/home?q=1&size=5&f=html');

        expect(url).toBe('/feature/home?q=1&f=html');
      });

      it('should remove param and preserve fragment', () => {
        const url = urlUtils.removeParams(['size'], '/feature/home?size=5#H2');

        expect(url).toBe('/feature/home#H2');
      });

      it('should remove multiple params', () => {
        const url = urlUtils.removeParams(['z', 'a'], '/home?z=11111&l=en_US&a=true#H2');

        expect(url).toBe('/home?l=en_US#H2');
      });
    });
  });

  describe('setUrlFragment', () => {
    it('should set fragment when url has no fragment', () => {
      const url = urlUtils.setUrlFragment('/home/feature', 'usage');

      expect(url).toBe('/home/feature#usage');
    });

    it('should set fragment when url has existing fragment', () => {
      const url = urlUtils.setUrlFragment('/home/feature#overview', 'usage');

      expect(url).toBe('/home/feature#usage');
    });

    it('should set fragment when given fragment includes #', () => {
      const url = urlUtils.setUrlFragment('/home/feature#overview', '#install');

      expect(url).toBe('/home/feature#install');
    });
  });
});
