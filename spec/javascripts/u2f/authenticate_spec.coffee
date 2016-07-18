#= require u2f/authenticate
#= require u2f/util
#= require u2f/error
#= require u2f
#= require ./mock_u2f_device

describe 'U2FAuthenticate', ->
  fixture.load('u2f/authenticate')

  beforeEach ->
    @u2fDevice = new MockU2FDevice
    @container = $("#js-authenticate-u2f")
    @component = new U2FAuthenticate(@container, {sign_requests: []}, "token")
    @component.start()

  it 'allows authenticating via a U2F device', ->
    setupButton = @container.find("#js-login-u2f-device")
    setupMessage = @container.find("p")
    expect(setupMessage.text()).toContain('Insert your security key')
    expect(setupButton.text()).toBe('Login Via U2F Device')
    setupButton.trigger('click')

    inProgressMessage = @container.find("p")
    expect(inProgressMessage.text()).toContain("Trying to communicate with your device")

    @u2fDevice.respondToAuthenticateRequest({deviceData: "this is data from the device"})
    authenticatedMessage = @container.find("p")
    deviceResponse = @container.find('#js-device-response')
    expect(authenticatedMessage.text()).toContain("Click this button to authenticate with the GitLab server")
    expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}')

  describe "errors", ->
    it "displays an error message", ->
      setupButton = @container.find("#js-login-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToAuthenticateRequest({errorCode: "error!"})
      errorMessage = @container.find("p")
      expect(errorMessage.text()).toContain("There was a problem communicating with your device")

    it "allows retrying authentication after an error", ->
      setupButton = @container.find("#js-login-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToAuthenticateRequest({errorCode: "error!"})
      retryButton = @container.find("#js-u2f-try-again")
      retryButton.trigger('click')

      setupButton = @container.find("#js-login-u2f-device")
      setupButton.trigger('click')
      @u2fDevice.respondToAuthenticateRequest({deviceData: "this is data from the device"})
      authenticatedMessage = @container.find("p")
      expect(authenticatedMessage.text()).toContain("Click this button to authenticate with the GitLab server")
