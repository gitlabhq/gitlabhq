/* eslint-disable space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-unused-expressions, no-return-assign, no-param-reassign, max-len */

(function() {
  this.MockU2FDevice = (function() {
    function MockU2FDevice() {
      this.respondToAuthenticateRequest = this.respondToAuthenticateRequest.bind(this);
      this.respondToRegisterRequest = this.respondToRegisterRequest.bind(this);
      window.u2f || (window.u2f = {});
      window.u2f.register = (function(_this) {
        return function(appId, registerRequests, signRequests, callback) {
          return _this.registerCallback = callback;
        };
      })(this);
      window.u2f.sign = (function(_this) {
        return function(appId, challenges, signRequests, callback) {
          return _this.authenticateCallback = callback;
        };
      })(this);
    }

    MockU2FDevice.prototype.respondToRegisterRequest = function(params) {
      return this.registerCallback(params);
    };

    MockU2FDevice.prototype.respondToAuthenticateRequest = function(params) {
      return this.authenticateCallback(params);
    };

    return MockU2FDevice;
  })();
}).call(window);
