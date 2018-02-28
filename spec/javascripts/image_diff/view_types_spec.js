import { viewTypes, isValidViewType } from '~/image_diff/view_types';

describe('viewTypes', () => {
  describe('isValidViewType', () => {
    it('should return true for TWO_UP', () => {
      expect(isValidViewType(viewTypes.TWO_UP)).toEqual(true);
    });

    it('should return true for SWIPE', () => {
      expect(isValidViewType(viewTypes.SWIPE)).toEqual(true);
    });

    it('should return true for ONION_SKIN', () => {
      expect(isValidViewType(viewTypes.ONION_SKIN)).toEqual(true);
    });

    it('should return false for non view types', () => {
      expect(isValidViewType('some-view-type')).toEqual(false);
      expect(isValidViewType(null)).toEqual(false);
      expect(isValidViewType(undefined)).toEqual(false);
      expect(isValidViewType('')).toEqual(false);
    });
  });
});
