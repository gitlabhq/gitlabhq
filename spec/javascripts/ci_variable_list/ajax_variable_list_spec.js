import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AjaxFormVariableList from '~/ci_variable_list/ajax_variable_list';

const VARIABLE_PATCH_ENDPOINT = 'http://test.host/frontend-fixtures/builds-project/variables';
const HIDE_CLASS = 'hide';

describe('AjaxFormVariableList', () => {
  preloadFixtures('projects/ci_cd_settings.html.raw');
  preloadFixtures('projects/ci_cd_settings_with_variables.html.raw');

  let container;
  let saveButton;
  let errorBox;

  let mock;
  let ajaxVariableList;

  beforeEach(() => {
    loadFixtures('projects/ci_cd_settings.html.raw');
    container = document.querySelector('.js-ci-variable-list-section');

    mock = new MockAdapter(axios);

    const ajaxVariableListEl = document.querySelector('.js-ci-variable-list-section');
    saveButton = ajaxVariableListEl.querySelector('.js-secret-variables-save-button');
    errorBox = container.querySelector('.js-ci-variable-error-box');
    ajaxVariableList = new AjaxFormVariableList({
      container,
      formField: 'variables',
      saveButton,
      errorBox,
      saveEndpoint: container.dataset.saveEndpoint,
    });

    spyOn(ajaxVariableList, 'updateRowsWithPersistedVariables').and.callThrough();
    spyOn(ajaxVariableList.variableList, 'toggleEnableRow').and.callThrough();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('onSaveClicked', () => {
    it('shows loading spinner while waiting for the request', (done) => {
      const loadingIcon = saveButton.querySelector('.js-secret-variables-save-loading-icon');

      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(() => {
        expect(loadingIcon.classList.contains(HIDE_CLASS)).toEqual(false);

        return [200, {}];
      });

      expect(loadingIcon.classList.contains(HIDE_CLASS)).toEqual(true);

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(loadingIcon.classList.contains(HIDE_CLASS)).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls `updateRowsWithPersistedVariables` with the persisted variables', (done) => {
      const variablesResponse = [{ id: 1, key: 'foo', value: 'bar' }];
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(200, {
        variables: variablesResponse,
      });

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(ajaxVariableList.updateRowsWithPersistedVariables)
            .toHaveBeenCalledWith(variablesResponse);
        })
        .then(done)
        .catch(done.fail);
    });

    it('hides any previous error box', (done) => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(200);

      expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('disables remove buttons while waiting for the request', (done) => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(() => {
        expect(ajaxVariableList.variableList.toggleEnableRow).toHaveBeenCalledWith(false);

        return [200, {}];
      });

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(ajaxVariableList.variableList.toggleEnableRow).toHaveBeenCalledWith(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('hides secret values', (done) => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(200, {});

      const row = container.querySelector('.js-row:first-child');
      const valueInput = row.querySelector('.js-ci-variable-input-value');
      const valuePlaceholder = row.querySelector('.js-secret-value-placeholder');

      valueInput.value = 'bar';
      $(valueInput).trigger('input');

      expect(valuePlaceholder.classList.contains(HIDE_CLASS)).toBe(true);
      expect(valueInput.classList.contains(HIDE_CLASS)).toBe(false);

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(valuePlaceholder.classList.contains(HIDE_CLASS)).toBe(false);
          expect(valueInput.classList.contains(HIDE_CLASS)).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows error box with validation errors', (done) => {
      const validationError = 'some validation error';
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(400, [
        validationError,
      ]);

      expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(false);
          expect(errorBox.textContent.trim().replace(/\n+\s+/m, ' ')).toEqual(`Validation failed ${validationError}`);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows flash message when request fails', (done) => {
      mock.onPatch(VARIABLE_PATCH_ENDPOINT).reply(500);

      expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);

      ajaxVariableList.onSaveClicked()
        .then(() => {
          expect(errorBox.classList.contains(HIDE_CLASS)).toEqual(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateRowsWithPersistedVariables', () => {
    beforeEach(() => {
      loadFixtures('projects/ci_cd_settings_with_variables.html.raw');
      container = document.querySelector('.js-ci-variable-list-section');

      const ajaxVariableListEl = document.querySelector('.js-ci-variable-list-section');
      saveButton = ajaxVariableListEl.querySelector('.js-secret-variables-save-button');
      errorBox = container.querySelector('.js-ci-variable-error-box');
      ajaxVariableList = new AjaxFormVariableList({
        container,
        formField: 'variables',
        saveButton,
        errorBox,
        saveEndpoint: container.dataset.saveEndpoint,
      });
    });

    it('removes variable that was removed', () => {
      expect(container.querySelectorAll('.js-row').length).toBe(3);

      container.querySelector('.js-row-remove-button').click();

      expect(container.querySelectorAll('.js-row').length).toBe(3);

      ajaxVariableList.updateRowsWithPersistedVariables([]);

      expect(container.querySelectorAll('.js-row').length).toBe(2);
    });

    it('updates new variable row with persisted ID', () => {
      const row = container.querySelector('.js-row:last-child');
      const idInput = row.querySelector('.js-ci-variable-input-id');
      const keyInput = row.querySelector('.js-ci-variable-input-key');
      const valueInput = row.querySelector('.js-ci-variable-input-value');

      keyInput.value = 'foo';
      $(keyInput).trigger('input');
      valueInput.value = 'bar';
      $(valueInput).trigger('input');

      expect(idInput.value).toEqual('');

      ajaxVariableList.updateRowsWithPersistedVariables([{
        id: 3,
        key: 'foo',
        value: 'bar',
      }]);

      expect(idInput.value).toEqual('3');
      expect(row.dataset.isPersisted).toEqual('true');
    });
  });
});
