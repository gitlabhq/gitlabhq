/* eslint-disable no-new */
import _ from 'underscore';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Sidebar from '~/right_sidebar';
import timeoutPromise from './helpers/set_timeout_promise_helper';

describe('Issuable right sidebar collapsed todo toggle', () => {
  const fixtureName = 'issues/open-issue.html.raw';
  const jsonFixtureName = 'todos/todos.json';
  let mock;

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

    mock = new MockAdapter(axios);

    mock.onPost(`${gl.TEST_HOST}/frontend-fixtures/issues-project/todos`).reply(() => {
      const response = _.clone(todoData);

      return [200, response];
    });

    mock.onDelete(/(.*)\/dashboard\/todos\/\d+$/).reply(() => {
      const response = _.clone(todoData);
      delete response.delete_path;

      return [200, response];
    });
  });

  afterEach(() => {
    mock.restore();
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

  it('toggle todo state', (done) => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setTimeout(() => {
      expect(
        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
      ).not.toBeNull();

      expect(
        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .fa-check-square'),
      ).not.toBeNull();

      done();
    });
  });

  it('toggle todo state of expanded todo toggle', (done) => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setTimeout(() => {
      expect(
        document.querySelector('.issuable-sidebar-header .js-issuable-todo').textContent.trim(),
      ).toBe('Mark todo as done');

      done();
    });
  });

  it('toggles todo button tooltip', (done) => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setTimeout(() => {
      expect(
        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('data-original-title'),
      ).toBe('Mark todo as done');

      done();
    });
  });

  it('marks todo as done', (done) => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    timeoutPromise()
      .then(() => {
        expect(
          document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
        ).not.toBeNull();

        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();
      })
      .then(timeoutPromise)
      .then(() => {
        expect(
          document.querySelector('.js-issuable-todo.sidebar-collapsed-icon .todo-undone'),
        ).toBeNull();

        expect(
          document.querySelector('.issuable-sidebar-header .js-issuable-todo').textContent.trim(),
        ).toBe('Add todo');
      })
      .then(done)
      .catch(done.fail);
  });

  it('updates aria-label to mark todo as done', (done) => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    setTimeout(() => {
      expect(
        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('aria-label'),
      ).toBe('Mark todo as done');

      done();
    });
  });

  it('updates aria-label to add todo', (done) => {
    document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();

    timeoutPromise()
      .then(() => {
        expect(
          document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('aria-label'),
        ).toBe('Mark todo as done');

        document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').click();
      })
      .then(timeoutPromise)
      .then(() => {
        expect(
          document.querySelector('.js-issuable-todo.sidebar-collapsed-icon').getAttribute('aria-label'),
        ).toBe('Add todo');
      })
      .then(done)
      .catch(done.fail);
  });
});
