###
//= require u2f/register
###
###
//= require u2f/util
###
###
//= require u2f/error
###
###
//= require u2f
###
###
//= require ./mock_u2f_device
###

describe 'U2FRegister', ->
  fixture.load('u2f/register')

  beforeEach ->
    @u2fDevice = new MockU2FDevice
    @container = $("#js-register-u2f")
    @component = new U2FRegister(@container, $("#js-register-u2f-templates"), {}, "token")
    @component.start()

  it 'allows registering a U2F device', ->
    setupButton = @container.find("#js-setup-u2f-device")
    expect(setupButton.text()).toBe('Setup New U2F Device')
    setupButton.trigger('click')

    inProgressMessage = @container.children("p")
    expect(inProgressMessage.text()).toContain("Trying to communicate with your device")

    @u2fDevice.respondToRegisterRequest({deviceData: "this is data from the device"})
    registeredMessage = @container.find('p')
    deviceResponse = @container.find('#js-device-response')
    expect(registeredMessage.text()).toContain("Your device was successfully set up!")
    expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}')

  describe "errors", ->
    it "doesn't allow the same device to be registered twice (for the same user", ->
      setupButton = @container.find("#js-setup-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToRegisterRequest({errorCode: 4})
      errorMessage = @container.find("p")
      expect(errorMessage.text()).toContain("already been registered with us")

    it "displays an error message for other errors", ->
      setupButton = @container.find("#js-setup-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToRegisterRequest({errorCode: "error!"})
      errorMessage = @container.find("p")
      expect(errorMessage.text()).toContain("There was a problem communicating with your device")

    it "allows retrying registration after an error", ->
      setupButton = @container.find("#js-setup-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToRegisterRequest({errorCode: "error!"})
      retryButton = @container.find("#U2FTryAgain")
      retryButton.trigger('click')

      setupButton = @container.find("#js-setup-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToRegisterRequest({deviceData: "this is data from the device"})
      registeredMessage = @container.find("p")
      expect(registeredMessage.text()).toContain("Your device was successfully set up!")
