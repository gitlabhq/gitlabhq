import { calculateTop, createArrowStyles } from '~/fly_out_nav';

describe('Fly out sidebar navigation', () => {
  describe('calculateTop', () => {
    it('returns boundingRect top', () => {
      const boundingRect = {
        top: 100,
      };

      expect(
        calculateTop(boundingRect, 100),
      ).toBe(100);
    });

    it('returns boundingRect - bottomOverflow', () => {
      const boundingRect = {
        top: window.innerHeight,
      };

      expect(
        calculateTop(boundingRect, 100),
      ).toBe(window.innerHeight - 100);
    });
  });

  describe('createArrowStyles', () => {
    it('returns translate3d styles', () => {
      const boundingRect = {
        top: 100,
      };

      expect(
        createArrowStyles(boundingRect, 50),
      ).toContain('translate3d(0, 50px, 0)');
    });
  });
});
