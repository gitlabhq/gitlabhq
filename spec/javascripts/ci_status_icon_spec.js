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
    'not_found',
  ];

  statuses.forEach((status) => {
    it(`should export a ${status} svg`, () => {
      const key = `${status.toUpperCase()}_SVG`;

      expect(Object.hasOwnProperty.call(icons, key)).toBe(true);
      expect(icons[key]).toMatch(/^<svg/);
    });
  });

  describe('default export map', () => {
    statuses.forEach((status) => {
      const iconName = `icon_status_${status}`;

      it(`should have a '${iconName}' key`, () => {
        expect(Object.hasOwnProperty.call(icons.default, iconName)).toBe(true);
      });
    });
  });
});
