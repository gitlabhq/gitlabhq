import $ from 'jquery';
import initTodoToggle from '~/header';

describe('Header', function () {
  const todosPendingCount = '.todos-count';
  const fixtureTemplate = 'issues/open-issue.html.raw';

  function isTodosCountHidden() {
    return $(todosPendingCount).hasClass('hidden');
  }

  function triggerToggle(newCount) {
    $(document).trigger('todo:toggle', newCount);
  }

  preloadFixtures(fixtureTemplate);
  beforeEach(() => {
    initTodoToggle();
    loadFixtures(fixtureTemplate);
  });

  it('should update todos-count after receiving the todo:toggle event', () => {
    triggerToggle('5');
    expect($(todosPendingCount).text()).toEqual('5');
  });

  it('should hide todos-count when it is 0', () => {
    triggerToggle('0');
    expect(isTodosCountHidden()).toEqual(true);
  });

  it('should show todos-count when it is more than 0', () => {
    triggerToggle('10');
    expect(isTodosCountHidden()).toEqual(false);
  });

  describe('when todos-count is 1000', () => {
    beforeEach(() => {
      triggerToggle('1000');
    });

    it('should show todos-count', () => {
      expect(isTodosCountHidden()).toEqual(false);
    });

    it('should show 99+ for todos-count', () => {
      expect($(todosPendingCount).text()).toEqual('99+');
    });
  });
});
