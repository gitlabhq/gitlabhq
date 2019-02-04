import '~/commons/polyfills/element';

describe('Element polyfills', function() {
  beforeEach(() => {
    this.element = document.createElement('ul');
  });

  describe('matches', () => {
    it('returns true if element matches the selector', () => {
      expect(this.element.matches('ul')).toBeTruthy();
    });

    it("returns false if element doesn't match the selector", () => {
      expect(this.element.matches('.not-an-element')).toBeFalsy();
    });
  });

  describe('closest', () => {
    beforeEach(() => {
      this.childElement = document.createElement('li');
      this.element.appendChild(this.childElement);
    });

    it('returns the closest parent that matches the selector', () => {
      expect(this.childElement.closest('ul').toString()).toBe(this.element.toString());
    });

    it('returns itself if it matches the selector', () => {
      expect(this.childElement.closest('li').toString()).toBe(this.childElement.toString());
    });

    it('returns undefined if nothing matches the selector', () => {
      expect(this.childElement.closest('.no-an-element')).toBeFalsy();
    });
  });
});
