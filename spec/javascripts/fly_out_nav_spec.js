import {
  calculateTop,
  showSubLevelItems,
  canShowSubItems,
  canShowActiveSubItems,
  mouseEnterTopItems,
  mouseLeaveTopItem,
  getOpenMenu,
  setOpenMenu,
  mousePos,
  getHideSubItemsInterval,
  documentMouseMove,
  getHeaderHeight,
  setSidebar,
  subItemsMouseLeave,
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

    setOpenMenu(null);
  });

  afterEach(() => {
    document.body.innerHTML = '';
    breakpointSize = 'lg';
    mousePos.length = 0;

    setSidebar(null);
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

  describe('getHideSubItemsInterval', () => {
    beforeEach(() => {
      el.innerHTML = '<div class="sidebar-sub-level-items" style="position: fixed; top: 0; left: 100px; height: 150px;"></div>';
    });

    it('returns 0 if currentOpenMenu is nil', () => {
      expect(
        getHideSubItemsInterval(),
      ).toBe(0);
    });

    it('returns 0 if mousePos is empty', () => {
      expect(
        getHideSubItemsInterval(),
      ).toBe(0);
    });

    it('returns 0 when mouse above sub-items', () => {
      showSubLevelItems(el);
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top - 50,
      });

      expect(
        getHideSubItemsInterval(),
      ).toBe(0);
    });

    it('returns 0 when mouse is below sub-items', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');

      showSubLevelItems(el);
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: (el.getBoundingClientRect().top - subItems.getBoundingClientRect().height) + 50,
      });

      expect(
        getHideSubItemsInterval(),
      ).toBe(0);
    });

    it('returns 300 when mouse is moved towards sub-items', () => {
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });
      showSubLevelItems(el);
      documentMouseMove({
        clientX: el.getBoundingClientRect().left + 20,
        clientY: el.getBoundingClientRect().top + 10,
      });

      expect(
        getHideSubItemsInterval(),
      ).toBe(300);
    });
  });

  describe('mouseLeaveTopItem', () => {
    beforeEach(() => {
      spyOn(el.classList, 'remove');
    });

    it('removes is-over class if currentOpenMenu is null', () => {
      mouseLeaveTopItem(el);

      expect(
        el.classList.remove,
      ).toHaveBeenCalledWith('is-over');
    });

    it('removes is-over class if currentOpenMenu is null & there are sub-items', () => {
      el.innerHTML = '<div class="sidebar-sub-level-items" style="position: absolute;"></div>';

      mouseLeaveTopItem(el);

      expect(
        el.classList.remove,
      ).toHaveBeenCalledWith('is-over');
    });

    it('does not remove is-over class if currentOpenMenu is the passed in sub-items', () => {
      el.innerHTML = '<div class="sidebar-sub-level-items" style="position: absolute;"></div>';

      setOpenMenu(el.querySelector('.sidebar-sub-level-items'));
      mouseLeaveTopItem(el);

      expect(
        el.classList.remove,
      ).not.toHaveBeenCalled();
    });
  });

  describe('mouseEnterTopItems', () => {
    beforeEach(() => {
      el.innerHTML = '<div class="sidebar-sub-level-items" style="position: absolute; top: 0; left: 100px; height: 200px;"></div>';
    });

    it('shows sub-items after 0ms if no menu is open', (done) => {
      mouseEnterTopItems(el);

      expect(
        getHideSubItemsInterval(),
      ).toBe(0);

      setTimeout(() => {
        expect(
          el.querySelector('.sidebar-sub-level-items').style.display,
        ).toBe('block');

        done();
      });
    });

    it('shows sub-items after 300ms if a menu is currently open', (done) => {
      documentMouseMove({
        clientX: el.getBoundingClientRect().left,
        clientY: el.getBoundingClientRect().top,
      });

      setOpenMenu(el.querySelector('.sidebar-sub-level-items'));

      documentMouseMove({
        clientX: el.getBoundingClientRect().left + 20,
        clientY: el.getBoundingClientRect().top + 10,
      });

      mouseEnterTopItems(el, 0);

      expect(
        getHideSubItemsInterval(),
      ).toBe(300);

      setTimeout(() => {
        expect(
          el.querySelector('.sidebar-sub-level-items').style.display,
        ).toBe('block');

        done();
      });
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

    it('shows sub-items', () => {
      showSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).toBe('block');
    });

    it('shows collapsed only sub-items if icon only sidebar', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');
      const sidebar = document.createElement('div');
      sidebar.classList.add('sidebar-collapsed-desktop');
      subItems.classList.add('is-fly-out-only');

      setSidebar(sidebar);

      showSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).toBe('block');
    });

    it('does not show collapsed only sub-items if icon only sidebar', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');
      subItems.classList.add('is-fly-out-only');

      showSubLevelItems(el);

      expect(
        subItems.style.display,
      ).not.toBe('block');
    });

    it('sets transform of sub-items', () => {
      const sidebar = document.createElement('div');
      const subItems = el.querySelector('.sidebar-sub-level-items');

      sidebar.style.width = '200px';

      document.body.appendChild(sidebar);

      setSidebar(sidebar);
      showSubLevelItems(el);

      expect(
        subItems.style.transform,
      ).toBe(`translate3d(200px, ${Math.floor(el.getBoundingClientRect().top) - getHeaderHeight()}px, 0px)`);
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
      sidebar.classList.add('sidebar-collapsed-desktop');
      el.classList.add('active');

      setSidebar(sidebar);

      expect(
        canShowActiveSubItems(el),
      ).toBeTruthy();
    });
  });

  describe('subItemsMouseLeave', () => {
    beforeEach(() => {
      el.innerHTML = '<div class="sidebar-sub-level-items" style="position: absolute;"></div>';

      setOpenMenu(el.querySelector('.sidebar-sub-level-items'));
    });

    it('hides subMenu if element is not hovered', () => {
      subItemsMouseLeave(el);

      expect(
        getOpenMenu(),
      ).toBeNull();
    });

    it('does not hide subMenu if element is hovered', () => {
      el.classList.add('is-over');
      subItemsMouseLeave(el);

      expect(
        getOpenMenu(),
      ).not.toBeNull();
    });
  });
});
