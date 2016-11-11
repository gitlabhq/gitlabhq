/* eslint-disable */
//= require lib/utils/datetime_utility
//= require jquery
/*= require jquery-ui/datepicker */
/*= require gl_dropdown */
//= require due_date_select
(() => {
  describe('Due Date Select', () => {
    describe('parseSelectedDate()', () => {
      it('call create date object', () => {
        const $dom = $(fixture.preload('due_date_select.html')[0]);

        const dueDateSelect = new gl.DueDateSelect({
          $context: $dom,
          $dropdown: $dom.find('.js-due-date-select'),
          $loading: $dom.find('.block-loading')
        });

        spyOn(gl.utils, 'createDateObject');
        dueDateSelect.parseSelectedDate();
        expect(gl.utils.createDateObject).toHaveBeenCalledWith('2016-11-20');
      });
    });
  });
})();
