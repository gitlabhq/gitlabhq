import * as icons from '~/ci_status_icons';

describe('CI status icons', () => {
  const statuses = [
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

  statuses.forEach((status) => {
    it(`should export a ${status} svg`, () => {
      const key = `${status.toUpperCase()}_SVG`;

      expect(Object.hasOwnProperty.call(icons, key)).toBe(true);
      expect(icons[key]).toMatch(/^<svg/);
    });
  });

  describe('default export map', () => {
    const entityIconNames = [
      'icon_status_canceled',
      'icon_status_created',
      'icon_status_failed',
      'icon_status_manual',
      'icon_status_pending',
      'icon_status_running',
      'icon_status_skipped',
      'icon_status_success',
      'icon_status_warning',
    ];

    entityIconNames.forEach((iconName) => {
      it(`should have a '${iconName}' key`, () => {
        expect(Object.hasOwnProperty.call(icons.default, iconName)).toBe(true);
      });
    });
  });
});
