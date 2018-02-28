import * as imageUtility from '~/lib/utils/image_utility';

describe('imageUtility', () => {
  describe('isImageLoaded', () => {
    it('should return false when image.complete is false', () => {
      const element = {
        complete: false,
        naturalHeight: 100,
      };

      expect(imageUtility.isImageLoaded(element)).toEqual(false);
    });

    it('should return false when naturalHeight = 0', () => {
      const element = {
        complete: true,
        naturalHeight: 0,
      };

      expect(imageUtility.isImageLoaded(element)).toEqual(false);
    });

    it('should return true when image.complete and naturalHeight != 0', () => {
      const element = {
        complete: true,
        naturalHeight: 100,
      };

      expect(imageUtility.isImageLoaded(element)).toEqual(true);
    });
  });
});
