import { getCiStatusSvg, normalizeStatus } from '~/vue_shared/utils/get_ci_status_svg';

describe('#getCiStatusSvg', () => {
  const ciStatuses = [
    'canceled',
    'created',
    'failed',
    'manual',
    'pending',
    'running',
    'skipped',
    'success',
    'warning',
  ];

  ciStatuses.forEach((status) => {
    it(`returns a valid SVG string for ${status} status strings`, () => {
      expect(getCiStatusSvg({ status })).toContain('<svg');
    });
  });

  ciStatuses.forEach((status) => {
    it(`returns a valid SVG string for legacy ${status} status strings`, () => {
      const legacyPrefix = 'icon_status_';
      expect(getCiStatusSvg({ status: `${legacyPrefix}${status}` })).toContain('<svg');
    });
  });

  ciStatuses.forEach((status) => {
    it(`returns a valid SVG string for borderless ${status} status strings`, () => {
      expect(getCiStatusSvg({ status, borderless: true })).toContain('<svg');
    });
  });

  ciStatuses.forEach((status) => {
    it(`returns a valid SVG string for borderless legacy ${status} status strings`, () => {
      const legacyPrefix = 'icon_status_';
      expect(getCiStatusSvg({ status: `${legacyPrefix}${status}`, borderless: true })).toContain('<svg');
    });
  });

  describe('#normalizeStatus', () => {
    it('returns the normalized status for ruby syntax', () => {
      expect(normalizeStatus('icon_status_success')).toBe('success');
    });

    it('returns the normalized status for a plain status string', () => {
      expect(normalizeStatus('success')).toBe('success');
    });
  });
});
