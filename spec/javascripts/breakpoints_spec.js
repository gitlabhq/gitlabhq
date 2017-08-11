import bp, {
  breakpoints,
} from '~/breakpoints';

describe('breakpoints', () => {
  Object.keys(breakpoints).forEach((key) => {
    const size = breakpoints[key];

    it(`returns ${key} when larger than ${size}`, () => {
      spyOn(bp, 'windowWidth').and.returnValue(size + 10);

      expect(bp.getBreakpointSize()).toBe(key);
    });
  });
});
