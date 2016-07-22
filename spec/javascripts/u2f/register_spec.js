
/*= require u2f/register */

/*= require u2f/util */

/*= require u2f/error */

/*= require u2f */

/*= require ./mock_u2f_device */
describe('U2FRegister', function() {
  fixture.load('u2f/register');
  beforeEach(function() {
    this.u2fDevice = new MockU2FDevice;
    this.container = $("#js-register-u2f");
    this.component = new U2FRegister(this.container, $("#js-register-u2f-templates"), {}, "token");
    return this.component.start();
  });
  it('allows registering a U2F device', function() {
    var deviceResponse, inProgressMessage, registeredMessage, setupButton;
    setupButton = this.container.find("#js-setup-u2f-device");
    expect(setupButton.text()).toBe('Setup New U2F Device');
    setupButton.trigger('click');
    inProgressMessage = this.container.children("p");
    expect(inProgressMessage.text()).toContain("Trying to communicate with your device");
    this.u2fDevice.respondToRegisterRequest({
      deviceData: "this is data from the device"
    });
    registeredMessage = this.container.find('p');
    deviceResponse = this.container.find('#js-device-response');
    expect(registeredMessage.text()).toContain("Your device was successfully set up!");
    return expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}');
  });
  return describe("errors", function() {
    it("doesn't allow the same device to be registered twice (for the same user", function() {
      var errorMessage, setupButton;
      setupButton = this.container.find("#js-setup-u2f-device");
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        errorCode: 4
      });
      errorMessage = this.container.find("p");
      return expect(errorMessage.text()).toContain("already been registered with us");
    });
    it("displays an error message for other errors", function() {
      var errorMessage, setupButton;
      setupButton = this.container.find("#js-setup-u2f-device");
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        errorCode: "error!"
      });
      errorMessage = this.container.find("p");
      return expect(errorMessage.text()).toContain("There was a problem communicating with your device");
    });
    return it("allows retrying registration after an error", function() {
      var registeredMessage, retryButton, setupButton;
      setupButton = this.container.find("#js-setup-u2f-device");
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        errorCode: "error!"
      });
      retryButton = this.container.find("#U2FTryAgain");
      retryButton.trigger('click');
      setupButton = this.container.find("#js-setup-u2f-device");
      setupButton.trigger('click');
      this.u2fDevice.respondToRegisterRequest({
        deviceData: "this is data from the device"
      });
      registeredMessage = this.container.find("p");
      return expect(registeredMessage.text()).toContain("Your device was successfully set up!");
    });
  });
});
