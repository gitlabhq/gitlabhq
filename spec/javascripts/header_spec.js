/* eslint-disable space-before-function-paren, no-var */

require('~/header');
require('~/lib/utils/text_utility');

(function() {
  describe('Header', function() {
    var todosPendingCount = '.todos-count';
    var fixtureTemplate = 'issues/open-issue.html.raw';

    function isTodosCountHidden() {
      return $(todosPendingCount).hasClass('hidden');
    }

    function triggerToggle(newCount) {
      $(document).trigger('todo:toggle', newCount);
    }

    preloadFixtures(fixtureTemplate);
    beforeEach(function() {
      loadFixtures(fixtureTemplate);
    });

    it('should update todos-count after receiving the todo:toggle event', function() {
      triggerToggle(5);
      expect($(todosPendingCount).text()).toEqual('5');
    });

    it('should hide todos-count when it is 0', function() {
      triggerToggle(0);
      expect(isTodosCountHidden()).toEqual(true);
    });

    it('should show todos-count when it is more than 0', function() {
      triggerToggle(10);
      expect(isTodosCountHidden()).toEqual(false);
    });

    describe('when todos-count is 1000', function() {
      beforeEach(function() {
        triggerToggle(1000);
      });

      it('should show todos-count', function() {
        expect(isTodosCountHidden()).toEqual(false);
      });

      it('should show 99+ for todos-count', function() {
        expect($(todosPendingCount).text()).toEqual('99+');
      });
    });
  });
}).call(window);
