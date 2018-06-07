import { webIDEUrl } from '~/lib/utils/url_utility';

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
});
