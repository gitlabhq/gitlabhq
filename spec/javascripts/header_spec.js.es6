/*= require header */
/*= require lib/utils/text_utility */

describe('Header', () => {
  const fixtureTemplate = 'header.html';

  const isTodosCountHidden = () => {
    const countContainer = document.querySelector('.todos-pending-count');
    return countContainer !== null ? countContainer.classList.contains('hidden') : null;
  };

  const triggerToggle = (newCount) => {
    const toggleTodoEvent = new CustomEvent('todo:toggle', {
      detail: {
        count: newCount,
      },
    });

    document.dispatchEvent(toggleTodoEvent);
  };

  fixture.preload(fixtureTemplate);
  beforeEach(() => {
    fixture.load(fixtureTemplate);
  });

  it('should update todos-pending-count after receiving the todo:toggle event', () => {
    triggerToggle(5);
    expect(document.querySelector('.todos-pending-count').textContent).toEqual('5');
  });

  it('should hide todos-pending-count when it is 0', () => {
    triggerToggle(0);
    expect(isTodosCountHidden()).toEqual(true);
  });

  it('should show todos-pending-count when it is more than 0', () => {
    triggerToggle(10);
    expect(isTodosCountHidden()).toEqual(false);
  });

  describe('when todos-pending-count is 1000', () => {
    beforeEach(() => {
      triggerToggle(1000);
    });

    it('should show todos-pending-count', () => {
      expect(isTodosCountHidden()).toEqual(false);
    });

    it('should add delimiter to todos-pending-count', () => {
      expect(document.querySelector('.todos-pending-count').textContent).toEqual('1,000');
    });
  });
});

