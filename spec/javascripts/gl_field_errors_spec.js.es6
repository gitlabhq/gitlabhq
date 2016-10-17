//= require jquery
//= require gl_field_errors

((global) => {
  fixture.preload('gl_field_errors.html');

  describe('GL Style Field Errors', function() {
    beforeEach(function() {
      fixture.load('gl_field_errors.html');
      const $form = this.$form = $('form.show-gl-field-errors');
      this.fieldErrors = new global.GlFieldErrors($form);
    });

    it('should properly initialize the form', function() {
      expect(this.$form).toBeDefined();
      expect(this.$form.length).toBe(1);
      expect(this.fieldErrors).toBeDefined();
      const inputs = this.fieldErrors.state.inputs;
      expect(inputs.length).toBe(5);
    });

    it('should ignore elements with custom error handling', function() {
      const customErrorFlag = 'no-gl-field-errors';
      const customErrorElem = $(`.${customErrorFlag}`);

      expect(customErrorElem.length).toBe(1);

      const customErrors = this.fieldErrors.state.inputs.filter((input) => {
       return input.inputElement.hasClass(customErrorFlag);
      });
      expect(customErrors.length).toBe(0);
    });

    it('should not show any errors before submit attempt', function() {
      this.$form.find('.email').val('not-a-valid-email').keyup();
      this.$form.find('.text-required').val('').keyup();
      this.$form.find('.alphanumberic').val('?---*').keyup();

      const errorsShown = this.$form.find('.gl-field-error-outline');
      expect(errorsShown.length).toBe(0);
    });

    it('should show errors when input valid is submitted', function() {
      this.$form.find('.email').val('not-a-valid-email').keyup();
      this.$form.find('.text-required').val('').keyup();
      this.$form.find('.alphanumberic').val('?---*').keyup();

      this.$form.submit();

      const errorsShown = this.$form.find('.gl-field-error-outline');
      expect(errorsShown.length).toBe(4);
    });

    it('should properly track validity state on input after invalid submission attempt', function() {
      this.$form.submit();

      const emailInputModel = this.fieldErrors.state.inputs[1];
      const fieldState = emailInputModel.state;
      const emailInputElement = emailInputModel.inputElement;

      // No input
      expect(emailInputElement).toHaveClass('gl-field-error-outline');
      expect(fieldState.empty).toBe(true);
      expect(fieldState.valid).toBe(false);

      // Then invalid input
      emailInputElement.val('not-a-valid-email').keyup();
      expect(emailInputElement).toHaveClass('gl-field-error-outline');
      expect(fieldState.empty).toBe(false);
      expect(fieldState.valid).toBe(false);

      // Then valid input
      emailInputElement.val('email@gitlab.com').keyup();
      expect(emailInputElement).not.toHaveClass('gl-field-error-outline');
      expect(fieldState.empty).toBe(false);
      expect(fieldState.valid).toBe(true);

      // Then invalid input
      emailInputElement.val('not-a-valid-email').keyup();
      expect(emailInputElement).toHaveClass('gl-field-error-outline');
      expect(fieldState.empty).toBe(false);
      expect(fieldState.valid).toBe(false);

      // Then empty input
      emailInputElement.val('').keyup();
      expect(emailInputElement).toHaveClass('gl-field-error-outline');
      expect(fieldState.empty).toBe(true);
      expect(fieldState.valid).toBe(false);

      // Then valid input
      emailInputElement.val('email@gitlab.com').keyup();
      expect(emailInputElement).not.toHaveClass('gl-field-error-outline');
      expect(fieldState.empty).toBe(false);
      expect(fieldState.valid).toBe(true);
    });

    it('should properly infer error messages', function() {
      this.$form.submit();
      const trackedInputs = this.fieldErrors.state.inputs;
      const inputHasTitle = trackedInputs[1];
      const hasTitleErrorElem = inputHasTitle.inputElement.siblings('.gl-field-error');
      const inputNoTitle = trackedInputs[2];
      const noTitleErrorElem = inputNoTitle.inputElement.siblings('.gl-field-error');

      expect(noTitleErrorElem.text()).toBe('This field is required.');
      expect(hasTitleErrorElem.text()).toBe('Please provide a valid email address.');
    });

  });

})(window.gl || (window.gl = {}));
