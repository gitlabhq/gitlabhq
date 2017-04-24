import { borderlessIcons, baseIcons } from '~/vue_shared/utils/ci_status_svg_index';

describe('CI status icons index', () => {
  _.each(borderlessIcons, (svg, status) => {
    it(`should export a borderless ${status} svg`, () => {
      expect(Object.hasOwnProperty.call(borderlessIcons, status)).toBe(true);
      expect(borderlessIcons[status]).toMatch(/^<svg/);
    });
  });

  _.each(baseIcons, (svg, status) => {
    it(`should export a base ${status} svg`, () => {
      expect(Object.hasOwnProperty.call(baseIcons, status)).toBe(true);
      expect(baseIcons[status]).toMatch(/^<svg/);
    });
  });
});
