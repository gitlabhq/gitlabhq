import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';

describe('highlightCurrentUser', () => {
  let rootElement;
  let elements;

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-root-element">
        <div data-user="1">@first</div>
        <div data-user="2">@second</div>
      </div>
    `);
    rootElement = document.getElementById('dummy-root-element');
    elements = rootElement.querySelectorAll('[data-user]');
  });

  describe('without current user', () => {
    beforeEach(() => {
      window.gon = window.gon || {};
      window.gon.current_user_id = null;
    });

    afterEach(() => {
      delete window.gon.current_user_id;
    });

    it('does not highlight the user', () => {
      const initialHtml = rootElement.outerHTML;

      highlightCurrentUser(elements);

      expect(rootElement.outerHTML).toBe(initialHtml);
    });
  });

  describe('with current user', () => {
    beforeEach(() => {
      window.gon = window.gon || {};
      window.gon.current_user_id = 2;
    });

    afterEach(() => {
      delete window.gon.current_user_id;
    });

    it('highlights current user', () => {
      highlightCurrentUser(elements);

      expect(elements.length).toBe(2);
      expect(elements[0]).not.toHaveClass('current-user');
      expect(elements[1]).toHaveClass('current-user');
    });
  });
});
