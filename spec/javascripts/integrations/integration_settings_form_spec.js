import $ from 'jquery';
import MockAdaptor from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
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
    let mock;

    beforeEach(() => {
      mock = new MockAdaptor(axios);

      spyOn(axios, 'put').and.callThrough();

      integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
      formData = integrationSettingsForm.$form.serialize();
    });

    afterEach(() => {
      mock.restore();
    });

    it('should make an ajax request with provided `formData`', (done) => {
      integrationSettingsForm.testSettings(formData)
        .then(() => {
          expect(axios.put).toHaveBeenCalledWith(integrationSettingsForm.testEndPoint, formData);

          done();
        })
        .catch(done.fail);
    });

    it('should show error Flash with `Save anyway` action if ajax request responds with error in test', (done) => {
      const errorMessage = 'Test failed.';
      mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
        error: true,
        message: errorMessage,
        service_response: 'some error',
      });

      integrationSettingsForm.testSettings(formData)
        .then(() => {
          const $flashContainer = $('.flash-container');
          expect($flashContainer.find('.flash-text').text().trim()).toEqual('Test failed. some error');
          expect($flashContainer.find('.flash-action')).toBeDefined();
          expect($flashContainer.find('.flash-action').text().trim()).toEqual('Save anyway');

          done();
        })
        .catch(done.fail);
    });

    it('should submit form if ajax request responds without any error in test', (done) => {
      spyOn(integrationSettingsForm.$form, 'submit');

      mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
        error: false,
      });

      integrationSettingsForm.testSettings(formData)
        .then(() => {
          expect(integrationSettingsForm.$form.submit).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });

    it('should submit form when clicked on `Save anyway` action of error Flash', (done) => {
      spyOn(integrationSettingsForm.$form, 'submit');

      const errorMessage = 'Test failed.';
      mock.onPut(integrationSettingsForm.testEndPoint).reply(200, {
        error: true,
        message: errorMessage,
      });

      integrationSettingsForm.testSettings(formData)
        .then(() => {
          const $flashAction = $('.flash-container .flash-action');
          expect($flashAction).toBeDefined();

          $flashAction.get(0).click();
        })
        .then(() => {
          expect(integrationSettingsForm.$form.submit).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });

    it('should show error Flash if ajax request failed', (done) => {
      const errorMessage = 'Something went wrong on our end.';

      mock.onPut(integrationSettingsForm.testEndPoint).networkError();

      integrationSettingsForm.testSettings(formData)
        .then(() => {
          expect($('.flash-container .flash-text').text().trim()).toEqual(errorMessage);

          done();
        })
        .catch(done.fail);
    });

    it('should always call `toggleSubmitBtnState` with `false` once request is completed', (done) => {
      mock.onPut(integrationSettingsForm.testEndPoint).networkError();

      spyOn(integrationSettingsForm, 'toggleSubmitBtnState');

      integrationSettingsForm.testSettings(formData)
        .then(() => {
          expect(integrationSettingsForm.toggleSubmitBtnState).toHaveBeenCalledWith(false);

          done();
        })
        .catch(done.fail);
    });
  });
});
