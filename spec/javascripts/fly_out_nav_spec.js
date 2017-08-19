import {
  calculateTop,
  hideSubLevelItems,
  showSubLevelItems,
  canShowSubItems,
  canShowActiveSubItems,
  getHeaderHeight,
  setSidebar,
} from '~/fly_out_nav';
import bp from '~/breakpoints';

describe('Fly out sidebar navigation', () => {
  let el;
  let breakpointSize = 'lg';

  beforeEach(() => {
    el = document.createElement('div');
    el.style.position = 'relative';
    document.body.appendChild(el);

    spyOn(bp, 'getBreakpointSize').and.callFake(() => breakpointSize);
  });

  afterEach(() => {
    el.remove();
    breakpointSize = 'lg';
  });

  describe('calculateTop', () => {
    it('returns boundingRect top', () => {
      const boundingRect = {
        top: 100,
        height: 100,
      };

      expect(
        calculateTop(boundingRect, 100),
      ).toBe(100);
    });

    it('returns boundingRect - bottomOverflow', () => {
      const boundingRect = {
        top: window.innerHeight - 50,
        height: 100,
      };

      expect(
        calculateTop(boundingRect, 100),
      ).toBe(window.innerHeight - 50);
    });
  });

  describe('hideSubLevelItems', () => {
    beforeEach(() => {
      el.innerHTML = '<div class="sidebar-sub-level-items"></div>';
    });

    it('hides subitems', () => {
      hideSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).toBe('');
    });

    it('does not hude subitems on mobile', () => {
      breakpointSize = 'xs';

      hideSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).not.toBe('none');
    });

    it('removes is-over class', () => {
      spyOn(el.classList, 'remove');

      hideSubLevelItems(el);

      expect(
        el.classList.remove,
      ).toHaveBeenCalledWith('is-over');
    });

    it('removes is-above class from sub-items', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');

      spyOn(subItems.classList, 'remove');

      hideSubLevelItems(el);

      expect(
        subItems.classList.remove,
      ).toHaveBeenCalledWith('is-above');
    });

    it('does nothing if el has no sub-items', () => {
      el.innerHTML = '';

      spyOn(el.classList, 'remove');

      hideSubLevelItems(el);

      expect(
        el.classList.remove,
      ).not.toHaveBeenCalledWith();
    });
  });

  describe('showSubLevelItems', () => {
    beforeEach(() => {
      el.innerHTML = '<div class="sidebar-sub-level-items" style="position: absolute;"></div>';
    });

    it('adds is-over class to el', () => {
      spyOn(el.classList, 'add');

      showSubLevelItems(el);

      expect(
        el.classList.add,
      ).toHaveBeenCalledWith('is-over');
    });

    it('does not show sub-items on mobile', () => {
      breakpointSize = 'xs';

      showSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).not.toBe('block');
    });

    it('does not shows sub-items', () => {
      showSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).toBe('block');
    });

    it('sets transform of sub-items', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');
      showSubLevelItems(el);

      expect(
        subItems.style.transform,
      ).toBe(`translate3d(0px, ${Math.floor(el.getBoundingClientRect().top) - getHeaderHeight()}px, 0px)`);
    });

    it('sets is-above when element is above', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');
      subItems.style.height = `${window.innerHeight + el.offsetHeight}px`;
      el.style.top = `${window.innerHeight - el.offsetHeight}px`;

      spyOn(subItems.classList, 'add');

      showSubLevelItems(el);

      expect(
        subItems.classList.add,
      ).toHaveBeenCalledWith('is-above');
    });
  });

  describe('canShowSubItems', () => {
    it('returns true if on desktop size', () => {
      expect(
        canShowSubItems(),
      ).toBeTruthy();
    });

    it('returns false if on mobile size', () => {
      breakpointSize = 'xs';

      expect(
        canShowSubItems(),
      ).toBeFalsy();
    });
  });

  describe('canShowActiveSubItems', () => {
    afterEach(() => {
      setSidebar(null);
    });

    it('returns true by default', () => {
      expect(
        canShowActiveSubItems(el),
      ).toBeTruthy();
    });

    it('returns false when active & expanded sidebar', () => {
      const sidebar = document.createElement('div');
      el.classList.add('active');

      setSidebar(sidebar);

      expect(
        canShowActiveSubItems(el),
      ).toBeFalsy();
    });

    it('returns true when active & collapsed sidebar', () => {
      const sidebar = document.createElement('div');
      sidebar.classList.add('sidebar-icons-only');
      el.classList.add('active');

      setSidebar(sidebar);

      expect(
        canShowActiveSubItems(el),
      ).toBeTruthy();
    });
  });
});
