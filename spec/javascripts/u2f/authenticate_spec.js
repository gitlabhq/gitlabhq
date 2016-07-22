
/*= require u2f/authenticate */

/*= require u2f/util */

/*= require u2f/error */

/*= require u2f */

/*= require ./mock_u2f_device */
describe('U2FAuthenticate', function() {
  fixture.load('u2f/authenticate');
  beforeEach(function() {
    this.u2fDevice = new MockU2FDevice;
    this.container = $("#js-authenticate-u2f");
    this.component = new U2FAuthenticate(this.container, {
      sign_requests: []
    }, "token");
    return this.component.start();
  });
  it('allows authenticating via a U2F device', function() {
    var authenticatedMessage, deviceResponse, inProgressMessage, setupButton, setupMessage;
    setupButton = this.container.find("#js-login-u2f-device");
    setupMessage = this.container.find("p");
    expect(setupMessage.text()).toContain('Insert your security key');
    expect(setupButton.text()).toBe('Login Via U2F Device');
    setupButton.trigger('click');
    inProgressMessage = this.container.find("p");
    expect(inProgressMessage.text()).toContain("Trying to communicate with your device");
    this.u2fDevice.respondToAuthenticateRequest({
      deviceData: "this is data from the device"
    });
    authenticatedMessage = this.container.find("p");
    deviceResponse = this.container.find('#js-device-response');
    expect(authenticatedMessage.text()).toContain("Click this button to authenticate with the GitLab server");
    return expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}');
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
      var authenticatedMessage, retryButton, setupButton;
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
      authenticatedMessage = this.container.find("p");
      return expect(authenticatedMessage.text()).toContain("Click this button to authenticate with the GitLab server");
    });
  });
});
