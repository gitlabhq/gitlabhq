/*= require sidebar */
/*= require jquery */
/*= require jquery.cookie */
/*= require lib/utils/text_utility */

((global) => {
  describe('Dashboard', () => {
    const fixtureTemplate = 'dashboard.html';

    function todosCountText() {
      return $('.js-todos-count').text();
    }

    function triggerToggle(newCount) {
      $(document).trigger('todo:toggle', newCount);
    }

    fixture.preload(fixtureTemplate);
    beforeEach(() => {
      fixture.load(fixtureTemplate);
      new global.Sidebar();
    });

    it('should update todos-count after receiving the todo:toggle event', () => {
      triggerToggle(5);
      expect(todosCountText()).toEqual('5');
    });

    it('should display todos-count with delimiter', () => {
      triggerToggle(1000);
      expect(todosCountText()).toEqual('1,000');

      triggerToggle(1000000);
      expect(todosCountText()).toEqual('1,000,000');
    });
  });

})(window.gl);
