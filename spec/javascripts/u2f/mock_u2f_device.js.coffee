class @MockU2FDevice
  constructor: () ->
    window.u2f ||= {}

    window.u2f.register = (appId, registerRequests, signRequests, callback) =>
      @registerCallback = callback

    window.u2f.sign = (appId, challenges, signRequests, callback) =>
      @authenticateCallback = callback

  respondToRegisterRequest: (params) =>
    @registerCallback(params)

  respondToAuthenticateRequest: (params) =>
    @authenticateCallback(params)
