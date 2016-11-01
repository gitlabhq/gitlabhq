/* eslint-disable */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.MockU2FDevice = (function() {
    function MockU2FDevice() {
      this.respondToAuthenticateRequest = bind(this.respondToAuthenticateRequest, this);
      this.respondToRegisterRequest = bind(this.respondToRegisterRequest, this);
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

}).call(this);
