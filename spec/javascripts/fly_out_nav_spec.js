import { calculateTop } from '~/fly_out_nav';

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
});
