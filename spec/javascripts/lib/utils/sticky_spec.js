import { isSticky } from '~/lib/utils/sticky';

describe('sticky', () => {
  const el = {
    offsetTop: 0,
    classList: {},
  };

  beforeEach(() => {
    el.offsetTop = 0;
    el.classList.add = jasmine.createSpy('spy');
    el.classList.remove = jasmine.createSpy('spy');
  });

  describe('classList.remove', () => {
    it('does not call classList.remove when stuck', () => {
      isSticky(el, 0, 0);

      expect(
        el.classList.remove,
      ).not.toHaveBeenCalled();
    });

    it('calls classList.remove when not stuck', () => {
      el.offsetTop = 10;
      isSticky(el, 0, 0);

      expect(
        el.classList.remove,
      ).toHaveBeenCalledWith('is-stuck');
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
  });
});
