import $ from 'jquery';
import ScrollHelper from '~/helpers/scroll_helper';

describe('ScrollHelper', () => {
  describe('setScrollWidth', () => {
    it('calls getScrollWidth and sets data-scroll-width', () => {
      const width = 10;

      spyOn($.fn, 'attr');
      spyOn(ScrollHelper, 'getScrollWidth').and.returnValue(width);

      ScrollHelper.setScrollWidth();

      expect(ScrollHelper.getScrollWidth).toHaveBeenCalled();
      expect($.fn.attr).toHaveBeenCalledWith('data-scroll-width', width);
    });
  });
});
