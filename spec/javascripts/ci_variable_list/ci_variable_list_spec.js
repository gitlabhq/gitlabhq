import $ from 'jquery';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import VariableList from '~/ci_variable_list/ci_variable_list';

const HIDE_CLASS = 'hide';

describe('VariableList', () => {
  preloadFixtures('pipeline_schedules/edit.html');
  preloadFixtures('pipeline_schedules/edit_with_variables.html');
  preloadFixtures('projects/ci_cd_settings.html');

  let $wrapper;
  let variableList;

  describe('with only key/value inputs', () => {
    describe('with no variables', () => {
      beforeEach(() => {
        loadFixtures('pipeline_schedules/edit.html');
        $wrapper = $('.js-ci-variable-list-section');

        variableList = new VariableList({
          container: $wrapper,
          formField: 'schedule',
        });
        variableList.init();
      });

      it('should remove the row when clicking the remove button', () => {
        $wrapper.find('.js-row-remove-button').trigger('click');

        expect($wrapper.find('.js-row').length).toBe(0);
      });

      it('should add another row when editing the last rows key input', () => {
        const $row = $wrapper.find('.js-row');
        $row
          .find('.js-ci-variable-input-key')
          .val('foo')
          .trigger('input');

        expect($wrapper.find('.js-row').length).toBe(2);

        // Check for the correct default in the new row
        const $keyInput = $wrapper.find('.js-row:last-child').find('.js-ci-variable-input-key');

        expect($keyInput.val()).toBe('');
      });

      it('should add another row when editing the last rows value textarea', () => {
        const $row = $wrapper.find('.js-row');
        $row
          .find('.js-ci-variable-input-value')
          .val('foo')
          .trigger('input');

        expect($wrapper.find('.js-row').length).toBe(2);

        // Check for the correct default in the new row
        const $valueInput = $wrapper.find('.js-row:last-child').find('.js-ci-variable-input-key');

        expect($valueInput.val()).toBe('');
      });

      it('should remove empty row after blurring', () => {
        const $row = $wrapper.find('.js-row');
        $row
          .find('.js-ci-variable-input-key')
          .val('foo')
          .trigger('input');

        expect($wrapper.find('.js-row').length).toBe(2);

        $row
          .find('.js-ci-variable-input-key')
          .val('')
          .trigger('input')
          .trigger('blur');

        expect($wrapper.find('.js-row').length).toBe(1);
      });
    });

    describe('with persisted variables', () => {
      beforeEach(() => {
        loadFixtures('pipeline_schedules/edit_with_variables.html');
        $wrapper = $('.js-ci-variable-list-section');

        variableList = new VariableList({
          container: $wrapper,
          formField: 'schedule',
        });
        variableList.init();
      });

      it('should have "Reveal values" button initially when there are already variables', () => {
        expect($wrapper.find('.js-secret-value-reveal-button').text()).toBe('Reveal values');
      });

      it('should reveal hidden values', () => {
        const $row = $wrapper.find('.js-row:first-child');
        const $inputValue = $row.find('.js-ci-variable-input-value');
        const $placeholder = $row.find('.js-secret-value-placeholder');

        expect($placeholder.hasClass(HIDE_CLASS)).toBe(false);
        expect($inputValue.hasClass(HIDE_CLASS)).toBe(true);

        // Reveal values
        $wrapper.find('.js-secret-value-reveal-button').click();

        expect($placeholder.hasClass(HIDE_CLASS)).toBe(true);
        expect($inputValue.hasClass(HIDE_CLASS)).toBe(false);
      });
    });
  });

  describe('with all inputs(key, value, protected)', () => {
    beforeEach(() => {
      loadFixtures('projects/ci_cd_settings.html');
      $wrapper = $('.js-ci-variable-list-section');

      $wrapper.find('.js-ci-variable-input-protected').attr('data-default', 'false');

      variableList = new VariableList({
        container: $wrapper,
        formField: 'variables',
      });
      variableList.init();
    });

    it('should not add another row when editing the last rows protected checkbox', done => {
      const $row = $wrapper.find('.js-row:last-child');
      $row.find('.ci-variable-protected-item .js-project-feature-toggle').click();

      getSetTimeoutPromise()
        .then(() => {
          expect($wrapper.find('.js-row').length).toBe(1);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should not add another row when editing the last rows masked checkbox', done => {
      const $row = $wrapper.find('.js-row:last-child');
      $row.find('.ci-variable-masked-item .js-project-feature-toggle').click();

      getSetTimeoutPromise()
        .then(() => {
          expect($wrapper.find('.js-row').length).toBe(1);
        })
        .then(done)
        .catch(done.fail);
    });

    describe('validateMaskability', () => {
      let $row;

      const maskingErrorElement = '.js-row:last-child .masking-validation-error';

      beforeEach(() => {
        $row = $wrapper.find('.js-row:last-child');
        $row.find('.ci-variable-masked-item .js-project-feature-toggle').click();
      });

      it('has a regex provided via a data attribute', () => {
        expect($wrapper.attr('data-maskable-regex')).toBe('^[a-zA-Z0-9_+=/@:-]{8,}$');
      });

      it('allows values that are 8 characters long', done => {
        $row.find('.js-ci-variable-input-value').val('looooong');

        getSetTimeoutPromise()
          .then(() => {
            expect($wrapper.find(maskingErrorElement)).toHaveClass('hide');
          })
          .then(done)
          .catch(done.fail);
      });

      it('rejects values that are shorter than 8 characters', done => {
        $row.find('.js-ci-variable-input-value').val('short');

        getSetTimeoutPromise()
          .then(() => {
            expect($wrapper.find(maskingErrorElement)).toBeVisible();
          })
          .then(done)
          .catch(done.fail);
      });

      it('allows values with base 64 characters', done => {
        $row.find('.js-ci-variable-input-value').val('abcABC123_+=/-');

        getSetTimeoutPromise()
          .then(() => {
            expect($wrapper.find(maskingErrorElement)).toHaveClass('hide');
          })
          .then(done)
          .catch(done.fail);
      });

      it('rejects values with other special characters', done => {
        $row.find('.js-ci-variable-input-value').val('1234567$');

        getSetTimeoutPromise()
          .then(() => {
            expect($wrapper.find(maskingErrorElement)).toBeVisible();
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('toggleEnableRow method', () => {
    beforeEach(() => {
      loadFixtures('pipeline_schedules/edit_with_variables.html');
      $wrapper = $('.js-ci-variable-list-section');

      variableList = new VariableList({
        container: $wrapper,
        formField: 'variables',
      });
      variableList.init();
    });

    it('should disable all key inputs', () => {
      expect($wrapper.find('.js-ci-variable-input-key:not([disabled])').length).toBe(3);

      variableList.toggleEnableRow(false);

      expect($wrapper.find('.js-ci-variable-input-key[disabled]').length).toBe(3);
    });

    it('should disable all remove buttons', () => {
      expect($wrapper.find('.js-row-remove-button:not([disabled])').length).toBe(3);

      variableList.toggleEnableRow(false);

      expect($wrapper.find('.js-row-remove-button[disabled]').length).toBe(3);
    });

    it('should enable all remove buttons', () => {
      variableList.toggleEnableRow(false);

      expect($wrapper.find('.js-row-remove-button[disabled]').length).toBe(3);

      variableList.toggleEnableRow(true);

      expect($wrapper.find('.js-row-remove-button:not([disabled])').length).toBe(3);
    });

    it('should enable all key inputs', () => {
      variableList.toggleEnableRow(false);

      expect($wrapper.find('.js-ci-variable-input-key[disabled]').length).toBe(3);

      variableList.toggleEnableRow(true);

      expect($wrapper.find('.js-ci-variable-input-key:not([disabled])').length).toBe(3);
    });
  });

  describe('hideValues', () => {
    beforeEach(() => {
      loadFixtures('projects/ci_cd_settings.html');
      $wrapper = $('.js-ci-variable-list-section');

      variableList = new VariableList({
        container: $wrapper,
        formField: 'variables',
      });
      variableList.init();
    });

    it('should hide value input and show placeholder stars', () => {
      const $row = $wrapper.find('.js-row');
      const $inputValue = $row.find('.js-ci-variable-input-value');
      const $placeholder = $row.find('.js-secret-value-placeholder');

      $row
        .find('.js-ci-variable-input-value')
        .val('foo')
        .trigger('input');

      expect($placeholder.hasClass(HIDE_CLASS)).toBe(true);
      expect($inputValue.hasClass(HIDE_CLASS)).toBe(false);

      variableList.hideValues();

      expect($placeholder.hasClass(HIDE_CLASS)).toBe(false);
      expect($inputValue.hasClass(HIDE_CLASS)).toBe(true);
    });
  });
});
