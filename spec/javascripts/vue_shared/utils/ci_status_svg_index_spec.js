import { borderlessIcons, baseIcons } from '~/vue_shared/utils/ci_status_svg_index';

describe('CI status icons index', () => {
  const statuses = [
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
    'blocked',
  ];

  statuses.forEach((status) => {
    it(`should export a borderless ${status} svg`, () => {
      expect(Object.hasOwnProperty.call(borderlessIcons, status)).toBe(true);
      expect(borderlessIcons[status]).toMatch(/^<svg/);
    });
  });

  statuses.forEach((status) => {
    it(`should export a base ${status} svg`, () => {
      expect(Object.hasOwnProperty.call(baseIcons, status)).toBe(true);
      expect(baseIcons[status]).toMatch(/^<svg/);
    });
  });
});
