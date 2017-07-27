import {
  setupPipelineVariableList,
  insertRow,
  removeRow,
} from '~/pipeline_schedules/setup_pipeline_variable_list';

describe('Pipeline Variable List', () => {
  let $markup;

  describe('insertRow', () => {
    it('should insert another row', () => {
      $markup = $(`<div>
        <li class="js-row">
          <input>
          <textarea></textarea>
        </li>
      </div>`);

      insertRow($markup.find('.js-row'));

      expect($markup.find('.js-row').length).toBe(2);
    });

    it('should clear `data-is-persisted` on cloned row', () => {
      $markup = $(`<div>
        <li class="js-row" data-is-persisted="true"></li>
      </div>`);

      insertRow($markup.find('.js-row'));

      const $lastRow = $markup.find('.js-row').last();
      expect($lastRow.attr('data-is-persisted')).toBe(undefined);
    });

    it('should clear inputs on cloned row', () => {
      $markup = $(`<div>
        <li class="js-row">
          <input value="foo">
          <textarea>bar</textarea>
        </li>
      </div>`);

      insertRow($markup.find('.js-row'));

      const $lastRow = $markup.find('.js-row').last();
      expect($lastRow.find('input').val()).toBe('');
      expect($lastRow.find('textarea').val()).toBe('');
    });
  });

  describe('removeRow', () => {
    it('should remove dynamic row', () => {
      $markup = $(`<div>
        <li class="js-row">
          <input>
          <textarea></textarea>
        </li>
      </div>`);

      removeRow($markup.find('.js-row'));

      expect($markup.find('.js-row').length).toBe(0);
    });

    it('should hide and mark to destroy with already persisted rows', () => {
      $markup = $(`<div>
        <li class="js-row" data-is-persisted="true">
          <input class="js-destroy-input">
        </li>
      </div>`);

      const $row = $markup.find('.js-row');
      removeRow($row);

      expect($row.find('.js-destroy-input').val()).toBe('1');
      expect($markup.find('.js-row').length).toBe(1);
    });
  });

  describe('setupPipelineVariableList', () => {
    beforeEach(() => {
      $markup = $(`<form>
        <li class="js-row">
          <input class="js-user-input" name="schedule[variables_attributes][][key]">
          <textarea class="js-user-input" name="schedule[variables_attributes][][value]"></textarea>
          <button class="js-row-remove-button"></button>
          <button class="js-row-add-button"></button>
        </li>
      </form>`);

      setupPipelineVariableList($markup);
    });

    it('should remove the row when clicking the remove button', () => {
      $markup.find('.js-row-remove-button').trigger('click');

      expect($markup.find('.js-row').length).toBe(0);
    });

    it('should add another row when editing the last rows key input', () => {
      const $row = $markup.find('.js-row');
      $row.find('input.js-user-input')
        .val('foo')
        .trigger('input');

      expect($markup.find('.js-row').length).toBe(2);
    });

    it('should add another row when editing the last rows value textarea', () => {
      const $row = $markup.find('.js-row');
      $row.find('textarea.js-user-input')
        .val('foo')
        .trigger('input');

      expect($markup.find('.js-row').length).toBe(2);
    });

    it('should remove empty row after blurring', () => {
      const $row = $markup.find('.js-row');
      $row.find('input.js-user-input')
        .val('foo')
        .trigger('input');

      expect($markup.find('.js-row').length).toBe(2);

      $row.find('input.js-user-input')
        .val('')
        .trigger('input')
        .trigger('blur');

      expect($markup.find('.js-row').length).toBe(1);
    });

    it('should clear out the `name` attribute on the inputs for the last empty row on form submission (avoid BE validation)', () => {
      const $row = $markup.find('.js-row');
      expect($row.find('input').attr('name')).toBe('schedule[variables_attributes][][key]');
      expect($row.find('textarea').attr('name')).toBe('schedule[variables_attributes][][value]');

      $markup.filter('form').submit();

      expect($row.find('input').attr('name')).toBe('');
      expect($row.find('textarea').attr('name')).toBe('');
    });
  });
});
