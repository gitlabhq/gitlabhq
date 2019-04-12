import bp, { breakpoints } from '~/breakpoints';

describe('breakpoints', () => {
  Object.keys(breakpoints).forEach(key => {
    const size = breakpoints[key];

    it(`returns ${key} when larger than ${size}`, () => {
      spyOn(bp, 'windowWidth').and.returnValue(size + 10);

      expect(bp.getBreakpointSize()).toBe(key);
    });
  });

  describe('isDesktop', () => {
    it('returns true when screen size is medium', () => {
      spyOn(bp, 'windowWidth').and.returnValue(breakpoints.md + 10);

      expect(bp.isDesktop()).toBe(true);
    });

    it('returns false when screen size is small', () => {
      spyOn(bp, 'windowWidth').and.returnValue(breakpoints.sm + 10);

      expect(bp.isDesktop()).toBe(false);
    });
  });
});
