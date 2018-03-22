import $ from 'jquery';
import * as urlUtils from '~/lib/utils/url_utility';
import Todos from '~/pages/dashboard/todos/index/todos';
import '~/lib/utils/common_utils';

describe('Todos', () => {
  preloadFixtures('todos/todos.html.raw');
  let todoItem;

  beforeEach(() => {
    loadFixtures('todos/todos.html.raw');
    todoItem = document.querySelector('.todos-list .todo');

    return new Todos();
  });

  describe('goToTodoUrl', () => {
    it('opens the todo url', (done) => {
      const todoLink = todoItem.dataset.url;

      spyOn(urlUtils, 'visitUrl').and.callFake((url) => {
        expect(url).toEqual(todoLink);
        done();
      });

      todoItem.click();
    });

    describe('meta click', () => {
      let visitUrlSpy;
      let windowOpenSpy;
      let metakeyEvent;

      beforeEach(() => {
        metakeyEvent = $.Event('click', { keyCode: 91, ctrlKey: true });
        visitUrlSpy = spyOn(urlUtils, 'visitUrl').and.callFake(() => {});
        windowOpenSpy = spyOn(window, 'open').and.callFake(() => {});
      });

      it('opens the todo url in another tab', () => {
        const todoLink = todoItem.dataset.url;

        $('.todos-list .todo').trigger(metakeyEvent);

        expect(visitUrlSpy).not.toHaveBeenCalled();
        expect(windowOpenSpy).toHaveBeenCalledWith(todoLink, '_blank');
      });

      it('run native funcionality when avatar is clicked', () => {
        $('.todos-list a').on('click', e => e.preventDefault());
        $('.todos-list img').trigger(metakeyEvent);

        expect(visitUrlSpy).not.toHaveBeenCalled();
        expect(windowOpenSpy).not.toHaveBeenCalled();
      });
    });
  });
});
