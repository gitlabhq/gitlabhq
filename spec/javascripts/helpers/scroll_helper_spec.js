import $ from 'jquery';
import ScrollHelper from '~/helpers/scroll_helper';

describe('ScrollHelper', () => {
  const width = 10;

  describe('getScrollWidth', () => {
    const parent = jasmine.createSpyObj('parent', ['css', 'appendTo', 'remove']);
    const child = jasmine.createSpyObj('child', ['css', 'appendTo', 'get']);
    let scrollWidth;

    beforeEach(() => {
      spyOn($.fn, 'init').and.returnValues(parent, child);
      spyOn(jasmine.Fixtures.prototype, 'cleanUp'); // disable jasmine-jquery cleanup, we dont want it but its imported in test_bundle :(

      parent.css.and.returnValue(parent);
      child.css.and.returnValue(child);
      child.get.and.returnValue({
        offsetWidth: width,
      });

      scrollWidth = ScrollHelper.getScrollWidth();
    });

    it('inserts 2 nested hidden scrollable divs, calls parents outerWidth, removes parent and returns the width', () => {
      const initArgs = $.fn.init.calls.allArgs();

      expect(initArgs[0][0]).toEqual('<div>');
      expect(initArgs[1][0]).toEqual('<div>');
      expect(parent.css).toHaveBeenCalledWith({
        visibility: 'hidden',
        width: 100,
        overflow: 'scroll',
      });
      expect(child.css).toHaveBeenCalledWith({
        width: 100,
      });
      expect(child.appendTo).toHaveBeenCalledWith(parent);
      expect(parent.appendTo).toHaveBeenCalledWith('body');
      expect(child.get).toHaveBeenCalledWith(0);
      expect(parent.remove).toHaveBeenCalled();
      expect(scrollWidth).toEqual(100 - width);
    });
  });

  describe('setScrollWidth', () => {
    it('calls getScrollWidth and sets data-scroll-width', () => {
      spyOn($.fn, 'find').and.callThrough();
      spyOn($.fn, 'attr');
      spyOn(ScrollHelper, 'getScrollWidth').and.returnValue(width);

      ScrollHelper.setScrollWidth();

      expect($.fn.find).toHaveBeenCalledWith('body');
      expect($.fn.attr).toHaveBeenCalledWith('data-scroll-width', width);
      expect(ScrollHelper.getScrollWidth).toHaveBeenCalled();
    });
  });
});
