import { isSticky } from '~/lib/utils/sticky';

describe('sticky', () => {
  const el = {
    offsetTop: 0,
    classList: {},
    parentNode: {},
    nextElementSibling: {},
  };
  let isStuck = false;

  beforeEach(() => {
    el.offsetTop = 0;
    el.classList.add = jasmine.createSpy('classListAdd');
    el.classList.remove = jasmine.createSpy('classListRemove');
    el.classList.contains = jasmine.createSpy('classListContains').and.callFake(() => isStuck);
    el.parentNode.insertBefore = jasmine.createSpy('insertBefore');
    el.nextElementSibling.remove = jasmine.createSpy('nextElementSibling');
    el.nextElementSibling.classList = {
      contains: jasmine.createSpy('classListContains').and.returnValue(true),
    };
  });

  afterEach(() => {
    isStuck = false;
  });

  describe('classList.remove', () => {
    it('does not call classList.remove when stuck', () => {
      isSticky(el, 0, 0);

      expect(
        el.classList.remove,
      ).not.toHaveBeenCalled();
    });

    it('calls classList.remove when no longer stuck', () => {
      isStuck = true;

      el.offsetTop = 10;
      isSticky(el, 0, 0);

      expect(
        el.classList.remove,
      ).toHaveBeenCalledWith('is-stuck');
    });

    it('removes placeholder when no longer stuck', () => {
      isStuck = true;

      el.offsetTop = 10;
      isSticky(el, 0, 0, true);

      expect(
        el.nextElementSibling.remove,
      ).toHaveBeenCalled();
    });
  });

  describe('classList.add', () => {
    it('calls classList.add when stuck', () => {
      isSticky(el, 0, 0);

      expect(
        el.classList.add,
      ).toHaveBeenCalledWith('is-stuck');
    });

    it('does not call classList.add when not stuck', () => {
      el.offsetTop = 10;
      isSticky(el, 0, 0);

      expect(
        el.classList.add,
      ).not.toHaveBeenCalled();
    });

    it('inserts placeholder element when stuck', () => {
      isSticky(el, 0, 0, true);

      expect(
        el.parentNode.insertBefore,
      ).toHaveBeenCalled();
    });
  });
});
