/* eslint-disable no-new */
import _ from 'underscore';
import Sidebar from '~/right_sidebar';

describe('Issuable right sidebar collapsed todo toggle', () => {
  const fixtureName = 'issues/open-issue.html.raw';
  const jsonFixtureName = 'todos/todos.json';

  preloadFixtures(fixtureName);
  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    const todoData = getJSONFixture(jsonFixtureName);
    new Sidebar();
    loadFixtures(fixtureName);

    document.querySelector('.js-right-sidebar')
      .classList.toggle('right-sidebar-expanded');
    document.querySelector('.js-right-sidebar')
      .classList.toggle('right-sidebar-collapsed');

    spyOn(jQuery, 'ajax').and.callFake((res) => {
      const d = $.Deferred();
      const response = _.clone(todoData);

      if (res.type === 'DELETE') {
        delete response.delete_path;
      }

      d.resolve(response);
      return d.promise();
    });
  });

  it('shows add todo button', () => {
    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon'),
    ).not.toBeNull();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .fa-plus-square'),
    ).not.toBeNull();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
    ).toBeNull();
  });

  it('sets default tooltip title', () => {
    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('title'),
    ).toBe('Add todo');
  });

  it('toggle todo state', () => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
    ).not.toBeNull();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .fa-check-square'),
    ).not.toBeNull();
  });

  it('toggle todo state of expanded todo toggle', () => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.issuable-sidebar-header .js-issuable-todo').textContent.trim(),
    ).toBe('Mark done');
  });

  it('toggles todo button tooltip', () => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('data-original-title'),
    ).toBe('Mark done');
  });

  it('marks todo as done', () => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
    ).not.toBeNull();

    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
    ).toBeNull();

    expect(
      document.querySelector('.issuable-sidebar-header .js-issuable-todo').textContent.trim(),
    ).toBe('Add todo');
  });

  it('updates aria-label to mark done', () => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('aria-label'),
    ).toBe('Mark done');
  });

  it('updates aria-label to add todo', () => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('aria-label'),
    ).toBe('Mark done');

    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    expect(
      document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('aria-label'),
    ).toBe('Add todo');
  });
});
