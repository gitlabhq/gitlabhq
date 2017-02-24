/* eslint-disable space-before-function-paren, no-var */

require('~/header');
require('~/lib/utils/text_utility');

(function() {
  describe('Header', function() {
    var todosPendingCount = '.todos-pending-count';
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

    it('should update todos-pending-count after receiving the todo:toggle event', function() {
      triggerToggle(5);
      expect($(todosPendingCount).text()).toEqual('5');
    });

    it('should hide todos-pending-count when it is 0', function() {
      triggerToggle(0);
      expect(isTodosCountHidden()).toEqual(true);
    });

    it('should show todos-pending-count when it is more than 0', function() {
      triggerToggle(10);
      expect(isTodosCountHidden()).toEqual(false);
    });

    describe('when todos-pending-count is 1000', function() {
      beforeEach(function() {
        triggerToggle(1000);
      });

      it('should show todos-pending-count', function() {
        expect(isTodosCountHidden()).toEqual(false);
      });

      it('should show 99+ for todos-pending-count', function() {
        expect($(todosPendingCount).text()).toEqual('99+');
      });
    });
  });
}).call(window);
