import domContentLoaded from '~/feature_highlight/feature_highlight_options';
import bp from '~/breakpoints';

describe('feature highlight options', () => {
  describe('domContentLoaded', () => {
    it('should not call highlightFeatures when breakpoint is xs', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('xs');

      expect(domContentLoaded()).toBe(false);
    });

    it('should not call highlightFeatures when breakpoint is sm', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('sm');

      expect(domContentLoaded()).toBe(false);
    });

    it('should not call highlightFeatures when breakpoint is md', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('md');

      expect(domContentLoaded()).toBe(false);
    });

    it('should call highlightFeatures when breakpoint is lg', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('lg');

      expect(domContentLoaded()).toBe(true);
    });
  });
});
