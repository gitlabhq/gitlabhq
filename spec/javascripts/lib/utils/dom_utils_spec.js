import { addClassIfElementExists } from '~/lib/utils/dom_utils';

describe('DOM Utils', () => {
  describe('addClassIfElementExists', () => {
    const className = 'biology';
    const fixture = `
      <div class="parent">
        <div class="child"></div>
      </div>
    `;

    let parentElement;

    beforeEach(() => {
      setFixtures(fixture);
      parentElement = document.querySelector('.parent');
    });

    it('adds class if element exists', () => {
      const childElement = parentElement.querySelector('.child');
      expect(childElement).not.toBe(null);

      addClassIfElementExists(childElement, className);

      expect(childElement.classList).toContain(className);
    });

    it('does not throw if element does not exist', () => {
      const childElement = parentElement.querySelector('.other-child');
      expect(childElement).toBe(null);

      addClassIfElementExists(childElement, className);
    });
  });
});
