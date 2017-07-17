import Todos from '~/todos';
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

      spyOn(gl.utils, 'visitUrl').and.callFake((url) => {
        expect(url).toEqual(todoLink);
        done();
      });

      todoItem.click();
    });

    describe('meta click', () => {
      let visitUrlSpy;

      beforeEach(() => {
        spyOn(gl.utils, 'isMetaClick').and.returnValue(true);
        visitUrlSpy = spyOn(gl.utils, 'visitUrl').and.callFake(() => {});
      });

      it('opens the todo url in another tab', (done) => {
        const todoLink = todoItem.dataset.url;

        spyOn(window, 'open').and.callFake((url, target) => {
          expect(todoLink).toEqual(url);
          expect(target).toEqual('_blank');
          done();
        });

        todoItem.click();
        expect(visitUrlSpy).not.toHaveBeenCalled();
      });

      it('opens the avatar\'s url in another tab when the avatar is clicked', (done) => {
        const avatarImage = todoItem.querySelector('img');
        const avatarUrl = avatarImage.parentElement.getAttribute('href');

        spyOn(window, 'open').and.callFake((url, target) => {
          expect(avatarUrl).toEqual(url);
          expect(target).toEqual('_blank');
          done();
        });

        avatarImage.click();
        expect(visitUrlSpy).not.toHaveBeenCalled();
      });
    });
  });
});
