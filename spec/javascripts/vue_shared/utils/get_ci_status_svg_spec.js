import getCiStatusSvg from '~/vue_shared/utils/get_ci_status_svg';

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
    'passed',
    'warning',
    'success_with_warnings',
    'failed_with_warnings',
    'info',
    'blocked',
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

  it('returns undefined for invalid status strings', () => {
    expect(getCiStatusSvg({ status: 'a-wop-dop-a-doo' })).toBeUndefined();
  });
});
