import IntegrationSettingsForm from '~/integrations/integration_settings_form';

describe('IntegrationSettingsForm', () => {
  const FIXTURE = 'services/edit_service.html.raw';
  preloadFixtures(FIXTURE);

  beforeEach(() => {
    loadFixtures(FIXTURE);
  });

  describe('contructor', () => {
    let integrationSettingsForm;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
      spyOn(integrationSettingsForm, 'init');
    });

    it('should initialize form element refs on class object', () => {
      // Form Reference
      expect(integrationSettingsForm.$form).toBeDefined();
      expect(integrationSettingsForm.$form.prop('nodeName')).toEqual('FORM');

      // Form Child Elements
      expect(integrationSettingsForm.$serviceToggle).toBeDefined();
      expect(integrationSettingsForm.$submitBtn).toBeDefined();
      expect(integrationSettingsForm.$submitBtnLoader).toBeDefined();
      expect(integrationSettingsForm.$submitBtnLabel).toBeDefined();
    });

    it('should initialize form metadata on class object', () => {
      expect(integrationSettingsForm.testEndPoint).toBeDefined();
      expect(integrationSettingsForm.canTestService).toBeDefined();
    });
  });

  describe('toggleServiceState', () => {
    let integrationSettingsForm;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
    });

    it('should remove `novalidate` attribute to form when called with `true`', () => {
      integrationSettingsForm.toggleServiceState(true);

      expect(integrationSettingsForm.$form.attr('novalidate')).not.toBeDefined();
    });

    it('should set `novalidate` attribute to form when called with `false`', () => {
      integrationSettingsForm.toggleServiceState(false);

      expect(integrationSettingsForm.$form.attr('novalidate')).toBeDefined();
    });
  });

  describe('toggleSubmitBtnLabel', () => {
    let integrationSettingsForm;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
    });

    it('should set Save button label to "Test settings and save changes" when serviceActive & canTestService are `true`', () => {
      integrationSettingsForm.canTestService = true;

      integrationSettingsForm.toggleSubmitBtnLabel(true);
      expect(integrationSettingsForm.$submitBtnLabel.text()).toEqual('Test settings and save changes');
    });

    it('should set Save button label to "Save changes" when either serviceActive or canTestService (or both) is `false`', () => {
      integrationSettingsForm.canTestService = false;

      integrationSettingsForm.toggleSubmitBtnLabel(false);
      expect(integrationSettingsForm.$submitBtnLabel.text()).toEqual('Save changes');

      integrationSettingsForm.toggleSubmitBtnLabel(true);
      expect(integrationSettingsForm.$submitBtnLabel.text()).toEqual('Save changes');

      integrationSettingsForm.canTestService = true;

      integrationSettingsForm.toggleSubmitBtnLabel(false);
      expect(integrationSettingsForm.$submitBtnLabel.text()).toEqual('Save changes');
    });
  });

  describe('toggleSubmitBtnState', () => {
    let integrationSettingsForm;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
    });

    it('should disable Save button and show loader animation when called with `true`', () => {
      integrationSettingsForm.toggleSubmitBtnState(true);

      expect(integrationSettingsForm.$submitBtn.is(':disabled')).toBeTruthy();
      expect(integrationSettingsForm.$submitBtnLoader.hasClass('hidden')).toBeFalsy();
    });

    it('should enable Save button and hide loader animation when called with `false`', () => {
      integrationSettingsForm.toggleSubmitBtnState(false);

      expect(integrationSettingsForm.$submitBtn.is(':disabled')).toBeFalsy();
      expect(integrationSettingsForm.$submitBtnLoader.hasClass('hidden')).toBeTruthy();
    });
  });

  describe('testSettings', () => {
    let integrationSettingsForm;
    let formData;

    beforeEach(() => {
      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
      formData = integrationSettingsForm.$form.serialize();
    });

    it('should make an ajax request with provided `formData`', () => {
      const deferred = $.Deferred();
      spyOn($, 'ajax').and.returnValue(deferred.promise());

      integrationSettingsForm.testSettings(formData);

      expect($.ajax).toHaveBeenCalledWith({
        type: 'PUT',
        url: integrationSettingsForm.testEndPoint,
        data: formData,
      });
    });

    it('should show error Flash with `Save anyway` action if ajax request responds with error in test', () => {
      const errorMessage = 'Test failed.';
      const deferred = $.Deferred();
      spyOn($, 'ajax').and.returnValue(deferred.promise());

      integrationSettingsForm.testSettings(formData);

      deferred.resolve({ error: true, message: errorMessage, service_response: 'some error' });

      const $flashContainer = $('.flash-container');
      expect($flashContainer.find('.flash-text').text().trim()).toEqual('Test failed. some error');
      expect($flashContainer.find('.flash-action')).toBeDefined();
      expect($flashContainer.find('.flash-action').text().trim()).toEqual('Save anyway');
    });

    it('should submit form if ajax request responds without any error in test', () => {
      const deferred = $.Deferred();
      spyOn($, 'ajax').and.returnValue(deferred.promise());

      integrationSettingsForm.testSettings(formData);

      spyOn(integrationSettingsForm.$form, 'submit');
      deferred.resolve({ error: false });

      expect(integrationSettingsForm.$form.submit).toHaveBeenCalled();
    });

    it('should submit form when clicked on `Save anyway` action of error Flash', () => {
      const errorMessage = 'Test failed.';
      const deferred = $.Deferred();
      spyOn($, 'ajax').and.returnValue(deferred.promise());

      integrationSettingsForm.testSettings(formData);

      deferred.resolve({ error: true, message: errorMessage });

      const $flashAction = $('.flash-container .flash-action');
      expect($flashAction).toBeDefined();

      spyOn(integrationSettingsForm.$form, 'submit');
      $flashAction.get(0).click();
      expect(integrationSettingsForm.$form.submit).toHaveBeenCalled();
    });

    it('should show error Flash if ajax request failed', () => {
      const errorMessage = 'Something went wrong on our end.';
      const deferred = $.Deferred();
      spyOn($, 'ajax').and.returnValue(deferred.promise());

      integrationSettingsForm.testSettings(formData);

      deferred.reject();

      expect($('.flash-container .flash-text').text().trim()).toEqual(errorMessage);
    });

    it('should always call `toggleSubmitBtnState` with `false` once request is completed', () => {
      const deferred = $.Deferred();
      spyOn($, 'ajax').and.returnValue(deferred.promise());

      integrationSettingsForm.testSettings(formData);

      spyOn(integrationSettingsForm, 'toggleSubmitBtnState');
      deferred.reject();

      expect(integrationSettingsForm.toggleSubmitBtnState).toHaveBeenCalledWith(false);
    });
  });
});
