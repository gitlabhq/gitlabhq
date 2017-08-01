import {
  calculateTop,
  hideSubLevelItems,
  showSubLevelItems,
} from '~/fly_out_nav';

describe('Fly out sidebar navigation', () => {
  let el;
  beforeEach(() => {
    el = document.createElement('div');
    document.body.appendChild(el);
  });

  afterEach(() => {
    el.remove();
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
      ).toBe('none');
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
      el.innerHTML = '<div class="sidebar-sub-level-items"></div>';
    });

    it('adds is-over class to el', () => {
      spyOn(el.classList, 'add');

      showSubLevelItems(el);

      expect(
        el.classList.add,
      ).toHaveBeenCalledWith('is-over');
    });

    it('shows sub-items', () => {
      showSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.display,
      ).toBe('block');
    });

    it('sets transform of sub-items', () => {
      showSubLevelItems(el);

      expect(
        el.querySelector('.sidebar-sub-level-items').style.transform,
      ).toBe(`translate3d(0px, ${el.offsetTop}px, 0px)`);
    });

    it('sets is-above when element is above', () => {
      const subItems = el.querySelector('.sidebar-sub-level-items');
      subItems.style.height = `${window.innerHeight + el.offsetHeight}px`;
      subItems.style.position = 'absolute';
      el.style.position = 'relative';
      el.style.top = `${window.innerHeight - el.offsetHeight}px`;

      spyOn(subItems.classList, 'add');

      showSubLevelItems(el);

      expect(
        subItems.classList.add,
      ).toHaveBeenCalledWith('is-above');
    });
  });
});
