import { isSticky } from '~/lib/utils/sticky';

describe('sticky', () => {
  let el;

  beforeEach(() => {
    document.body.innerHTML += `
      <div class="parent">
        <div id="js-sticky"></div>
      </div>
    `;

    el = document.getElementById('js-sticky');
  });

  afterEach(() => {
    el.parentNode.remove();
  });

  describe('when stuck', () => {
    it('does not remove is-stuck class', () => {
      isSticky(el, 0, el.offsetTop);
      isSticky(el, 0, el.offsetTop);

      expect(
        el.classList.contains('is-stuck'),
      ).toBeTruthy();
    });

    it('adds is-stuck class', () => {
      isSticky(el, 0, el.offsetTop);

      expect(
        el.classList.contains('is-stuck'),
      ).toBeTruthy();
    });

    it('inserts placeholder element', () => {
      isSticky(el, 0, el.offsetTop, true);

      expect(
        document.querySelector('.sticky-placeholder'),
      ).not.toBeNull();
    });
  });

  describe('when not stuck', () => {
    it('removes is-stuck class', () => {
      spyOn(el.classList, 'remove').and.callThrough();

      isSticky(el, 0, el.offsetTop);
      isSticky(el, 0, 0);

      expect(
        el.classList.remove,
      ).toHaveBeenCalledWith('is-stuck');
      expect(
        el.classList.contains('is-stuck'),
      ).toBeFalsy();
    });

    it('does not add is-stuck class', () => {
      isSticky(el, 0, 0);

      expect(
        el.classList.contains('is-stuck'),
      ).toBeFalsy();
    });

    it('removes placeholder', () => {
      isSticky(el, 0, el.offsetTop, true);
      isSticky(el, 0, 0, true);

      expect(
        document.querySelector('.sticky-placeholder'),
      ).toBeNull();
    });
  });
});
