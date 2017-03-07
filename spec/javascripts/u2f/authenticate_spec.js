/* eslint-disable space-before-function-paren, new-parens, quotes, comma-dangle, no-var, one-var, one-var-declaration-per-line, max-len */
/* global MockU2FDevice */
/* global U2FAuthenticate */

require('~/u2f/authenticate');
require('~/u2f/util');
require('~/u2f/error');
require('vendor/u2f');
require('./mock_u2f_device');

(function() {
  describe('U2FAuthenticate', function() {
    preloadFixtures('u2f/authenticate.html.raw');

    beforeEach(function() {
      loadFixtures('u2f/authenticate.html.raw');
      this.u2fDevice = new MockU2FDevice;
      this.container = $("#js-authenticate-u2f");
      this.component = new window.gl.U2FAuthenticate(
        this.container,
        '#js-login-u2f-form',
        {
          sign_requests: []
        },
        document.querySelector('#js-login-2fa-device'),
        document.querySelector('.js-2fa-form')
      );

      // bypass automatic form submission within renderAuthenticated
      spyOn(this.component, 'renderAuthenticated').and.returnValue(true);

      return this.component.start();
    });
    it('allows authenticating via a U2F device', function() {
      var inProgressMessage;
      inProgressMessage = this.container.find("p");
      expect(inProgressMessage.text()).toContain("Trying to communicate with your device");
      this.u2fDevice.respondToAuthenticateRequest({
        deviceData: "this is data from the device"
      });
      expect(this.component.renderAuthenticated).toHaveBeenCalledWith('{"deviceData":"this is data from the device"}');
    });
    return describe("errors", function() {
      it("displays an error message", function() {
        var errorMessage, setupButton;
        setupButton = this.container.find("#js-login-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToAuthenticateRequest({
          errorCode: "error!"
        });
        errorMessage = this.container.find("p");
        return expect(errorMessage.text()).toContain("There was a problem communicating with your device");
      });
      return it("allows retrying authentication after an error", function() {
        var retryButton, setupButton;
        setupButton = this.container.find("#js-login-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToAuthenticateRequest({
          errorCode: "error!"
        });
        retryButton = this.container.find("#js-u2f-try-again");
        retryButton.trigger('click');
        setupButton = this.container.find("#js-login-u2f-device");
        setupButton.trigger('click');
        this.u2fDevice.respondToAuthenticateRequest({
          deviceData: "this is data from the device"
        });
        expect(this.component.renderAuthenticated).toHaveBeenCalledWith('{"deviceData":"this is data from the device"}');
      });
    });
  });
}).call(window);
