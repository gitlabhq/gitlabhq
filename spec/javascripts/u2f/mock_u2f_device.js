/* eslint-disable prefer-rest-params, wrap-iife,
no-unused-expressions, no-return-assign, no-param-reassign*/

export default class MockU2FDevice {
  constructor() {
    this.respondToAuthenticateRequest = this.respondToAuthenticateRequest.bind(this);
    this.respondToRegisterRequest = this.respondToRegisterRequest.bind(this);
    window.u2f || (window.u2f = {});
    window.u2f.register = (function (_this) {
      return function (appId, registerRequests, signRequests, callback) {
        return _this.registerCallback = callback;
      };
    })(this);
    window.u2f.sign = (function (_this) {
      return function (appId, challenges, signRequests, callback) {
        return _this.authenticateCallback = callback;
      };
    })(this);
  }

  respondToRegisterRequest(params) {
    return this.registerCallback(params);
  }

  respondToAuthenticateRequest(params) {
    return this.authenticateCallback(params);
  }
}
