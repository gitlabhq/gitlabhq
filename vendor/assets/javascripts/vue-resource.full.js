/*!
 * vue-resource v0.9.3
 * https://github.com/vuejs/vue-resource
 * Released under the MIT License.
 */

(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global.VueResource = factory());
}(this, function () { 'use strict';

  /**
   * Promises/A+ polyfill v1.1.4 (https://github.com/bramstein/promis)
   */

  var RESOLVED = 0;
  var REJECTED = 1;
  var PENDING = 2;

  function Promise$2(executor) {

      this.state = PENDING;
      this.value = undefined;
      this.deferred = [];

      var promise = this;

      try {
          executor(function (x) {
              promise.resolve(x);
          }, function (r) {
              promise.reject(r);
          });
      } catch (e) {
          promise.reject(e);
      }
  }

  Promise$2.reject = function (r) {
      return new Promise$2(function (resolve, reject) {
          reject(r);
      });
  };

  Promise$2.resolve = function (x) {
      return new Promise$2(function (resolve, reject) {
          resolve(x);
      });
  };

  Promise$2.all = function all(iterable) {
      return new Promise$2(function (resolve, reject) {
          var count = 0,
              result = [];

          if (iterable.length === 0) {
              resolve(result);
          }

          function resolver(i) {
              return function (x) {
                  result[i] = x;
                  count += 1;

                  if (count === iterable.length) {
                      resolve(result);
                  }
              };
          }

          for (var i = 0; i < iterable.length; i += 1) {
              Promise$2.resolve(iterable[i]).then(resolver(i), reject);
          }
      });
  };

  Promise$2.race = function race(iterable) {
      return new Promise$2(function (resolve, reject) {
          for (var i = 0; i < iterable.length; i += 1) {
              Promise$2.resolve(iterable[i]).then(resolve, reject);
          }
      });
  };

  var p$1 = Promise$2.prototype;

  p$1.resolve = function resolve(x) {
      var promise = this;

      if (promise.state === PENDING) {
          if (x === promise) {
              throw new TypeError('Promise settled with itself.');
          }

          var called = false;

          try {
              var then = x && x['then'];

              if (x !== null && typeof x === 'object' && typeof then === 'function') {
                  then.call(x, function (x) {
                      if (!called) {
                          promise.resolve(x);
                      }
                      called = true;
                  }, function (r) {
                      if (!called) {
                          promise.reject(r);
                      }
                      called = true;
                  });
                  return;
              }
          } catch (e) {
              if (!called) {
                  promise.reject(e);
              }
              return;
          }

          promise.state = RESOLVED;
          promise.value = x;
          promise.notify();
      }
  };

  p$1.reject = function reject(reason) {
      var promise = this;

      if (promise.state === PENDING) {
          if (reason === promise) {
              throw new TypeError('Promise settled with itself.');
          }

          promise.state = REJECTED;
          promise.value = reason;
          promise.notify();
      }
  };

  p$1.notify = function notify() {
      var promise = this;

      nextTick(function () {
          if (promise.state !== PENDING) {
              while (promise.deferred.length) {
                  var deferred = promise.deferred.shift(),
                      onResolved = deferred[0],
                      onRejected = deferred[1],
                      resolve = deferred[2],
                      reject = deferred[3];

                  try {
                      if (promise.state === RESOLVED) {
                          if (typeof onResolved === 'function') {
                              resolve(onResolved.call(undefined, promise.value));
                          } else {
                              resolve(promise.value);
                          }
                      } else if (promise.state === REJECTED) {
                          if (typeof onRejected === 'function') {
                              resolve(onRejected.call(undefined, promise.value));
                          } else {
                              reject(promise.value);
                          }
                      }
                  } catch (e) {
                      reject(e);
                  }
              }
          }
      });
  };

  p$1.then = function then(onResolved, onRejected) {
      var promise = this;

      return new Promise$2(function (resolve, reject) {
          promise.deferred.push([onResolved, onRejected, resolve, reject]);
          promise.notify();
      });
  };

  p$1.catch = function (onRejected) {
      return this.then(undefined, onRejected);
  };

  var PromiseObj = window.Promise || Promise$2;

  function Promise$1(executor, context) {

      if (executor instanceof PromiseObj) {
          this.promise = executor;
      } else {
          this.promise = new PromiseObj(executor.bind(context));
      }

      this.context = context;
  }

  Promise$1.all = function (iterable, context) {
      return new Promise$1(PromiseObj.all(iterable), context);
  };

  Promise$1.resolve = function (value, context) {
      return new Promise$1(PromiseObj.resolve(value), context);
  };

  Promise$1.reject = function (reason, context) {
      return new Promise$1(PromiseObj.reject(reason), context);
  };

  Promise$1.race = function (iterable, context) {
      return new Promise$1(PromiseObj.race(iterable), context);
  };

  var p = Promise$1.prototype;

  p.bind = function (context) {
      this.context = context;
      return this;
  };

  p.then = function (fulfilled, rejected) {

      if (fulfilled && fulfilled.bind && this.context) {
          fulfilled = fulfilled.bind(this.context);
      }

      if (rejected && rejected.bind && this.context) {
          rejected = rejected.bind(this.context);
      }

      return new Promise$1(this.promise.then(fulfilled, rejected), this.context);
  };

  p.catch = function (rejected) {

      if (rejected && rejected.bind && this.context) {
          rejected = rejected.bind(this.context);
      }

      return new Promise$1(this.promise.catch(rejected), this.context);
  };

  p.finally = function (callback) {

      return this.then(function (value) {
          callback.call(this);
          return value;
      }, function (reason) {
          callback.call(this);
          return PromiseObj.reject(reason);
      });
  };

  var debug = false;
  var util = {};
  var array = [];
  function Util (Vue) {
      util = Vue.util;
      debug = Vue.config.debug || !Vue.config.silent;
  }

  function warn(msg) {
      if (typeof console !== 'undefined' && debug) {
          console.warn('[VueResource warn]: ' + msg);
      }
  }

  function error(msg) {
      if (typeof console !== 'undefined') {
          console.error(msg);
      }
  }

  function nextTick(cb, ctx) {
      return util.nextTick(cb, ctx);
  }

  function trim(str) {
      return str.replace(/^\s*|\s*$/g, '');
  }

  var isArray = Array.isArray;

  function isString(val) {
      return typeof val === 'string';
  }

  function isBoolean(val) {
      return val === true || val === false;
  }

  function isFunction(val) {
      return typeof val === 'function';
  }

  function isObject(obj) {
      return obj !== null && typeof obj === 'object';
  }

  function isPlainObject(obj) {
      return isObject(obj) && Object.getPrototypeOf(obj) == Object.prototype;
  }

  function isFormData(obj) {
      return typeof FormData !== 'undefined' && obj instanceof FormData;
  }

  function when(value, fulfilled, rejected) {

      var promise = Promise$1.resolve(value);

      if (arguments.length < 2) {
          return promise;
      }

      return promise.then(fulfilled, rejected);
  }

  function options(fn, obj, opts) {

      opts = opts || {};

      if (isFunction(opts)) {
          opts = opts.call(obj);
      }

      return merge(fn.bind({ $vm: obj, $options: opts }), fn, { $options: opts });
  }

  function each(obj, iterator) {

      var i, key;

      if (typeof obj.length == 'number') {
          for (i = 0; i < obj.length; i++) {
              iterator.call(obj[i], obj[i], i);
          }
      } else if (isObject(obj)) {
          for (key in obj) {
              if (obj.hasOwnProperty(key)) {
                  iterator.call(obj[key], obj[key], key);
              }
          }
      }

      return obj;
  }

  var assign = Object.assign || _assign;

  function merge(target) {

      var args = array.slice.call(arguments, 1);

      args.forEach(function (source) {
          _merge(target, source, true);
      });

      return target;
  }

  function defaults(target) {

      var args = array.slice.call(arguments, 1);

      args.forEach(function (source) {

          for (var key in source) {
              if (target[key] === undefined) {
                  target[key] = source[key];
              }
          }
      });

      return target;
  }

  function _assign(target) {

      var args = array.slice.call(arguments, 1);

      args.forEach(function (source) {
          _merge(target, source);
      });

      return target;
  }

  function _merge(target, source, deep) {
      for (var key in source) {
          if (deep && (isPlainObject(source[key]) || isArray(source[key]))) {
              if (isPlainObject(source[key]) && !isPlainObject(target[key])) {
                  target[key] = {};
              }
              if (isArray(source[key]) && !isArray(target[key])) {
                  target[key] = [];
              }
              _merge(target[key], source[key], deep);
          } else if (source[key] !== undefined) {
              target[key] = source[key];
          }
      }
  }

  function root (options, next) {

      var url = next(options);

      if (isString(options.root) && !url.match(/^(https?:)?\//)) {
          url = options.root + '/' + url;
      }

      return url;
  }

  function query (options, next) {

      var urlParams = Object.keys(Url.options.params),
          query = {},
          url = next(options);

      each(options.params, function (value, key) {
          if (urlParams.indexOf(key) === -1) {
              query[key] = value;
          }
      });

      query = Url.params(query);

      if (query) {
          url += (url.indexOf('?') == -1 ? '?' : '&') + query;
      }

      return url;
  }

  /**
   * URL Template v2.0.6 (https://github.com/bramstein/url-template)
   */

  function expand(url, params, variables) {

      var tmpl = parse(url),
          expanded = tmpl.expand(params);

      if (variables) {
          variables.push.apply(variables, tmpl.vars);
      }

      return expanded;
  }

  function parse(template) {

      var operators = ['+', '#', '.', '/', ';', '?', '&'],
          variables = [];

      return {
          vars: variables,
          expand: function (context) {
              return template.replace(/\{([^\{\}]+)\}|([^\{\}]+)/g, function (_, expression, literal) {
                  if (expression) {

                      var operator = null,
                          values = [];

                      if (operators.indexOf(expression.charAt(0)) !== -1) {
                          operator = expression.charAt(0);
                          expression = expression.substr(1);
                      }

                      expression.split(/,/g).forEach(function (variable) {
                          var tmp = /([^:\*]*)(?::(\d+)|(\*))?/.exec(variable);
                          values.push.apply(values, getValues(context, operator, tmp[1], tmp[2] || tmp[3]));
                          variables.push(tmp[1]);
                      });

                      if (operator && operator !== '+') {

                          var separator = ',';

                          if (operator === '?') {
                              separator = '&';
                          } else if (operator !== '#') {
                              separator = operator;
                          }

                          return (values.length !== 0 ? operator : '') + values.join(separator);
                      } else {
                          return values.join(',');
                      }
                  } else {
                      return encodeReserved(literal);
                  }
              });
          }
      };
  }

  function getValues(context, operator, key, modifier) {

      var value = context[key],
          result = [];

      if (isDefined(value) && value !== '') {
          if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
              value = value.toString();

              if (modifier && modifier !== '*') {
                  value = value.substring(0, parseInt(modifier, 10));
              }

              result.push(encodeValue(operator, value, isKeyOperator(operator) ? key : null));
          } else {
              if (modifier === '*') {
                  if (Array.isArray(value)) {
                      value.filter(isDefined).forEach(function (value) {
                          result.push(encodeValue(operator, value, isKeyOperator(operator) ? key : null));
                      });
                  } else {
                      Object.keys(value).forEach(function (k) {
                          if (isDefined(value[k])) {
                              result.push(encodeValue(operator, value[k], k));
                          }
                      });
                  }
              } else {
                  var tmp = [];

                  if (Array.isArray(value)) {
                      value.filter(isDefined).forEach(function (value) {
                          tmp.push(encodeValue(operator, value));
                      });
                  } else {
                      Object.keys(value).forEach(function (k) {
                          if (isDefined(value[k])) {
                              tmp.push(encodeURIComponent(k));
                              tmp.push(encodeValue(operator, value[k].toString()));
                          }
                      });
                  }

                  if (isKeyOperator(operator)) {
                      result.push(encodeURIComponent(key) + '=' + tmp.join(','));
                  } else if (tmp.length !== 0) {
                      result.push(tmp.join(','));
                  }
              }
          }
      } else {
          if (operator === ';') {
              result.push(encodeURIComponent(key));
          } else if (value === '' && (operator === '&' || operator === '?')) {
              result.push(encodeURIComponent(key) + '=');
          } else if (value === '') {
              result.push('');
          }
      }

      return result;
  }

  function isDefined(value) {
      return value !== undefined && value !== null;
  }

  function isKeyOperator(operator) {
      return operator === ';' || operator === '&' || operator === '?';
  }

  function encodeValue(operator, value, key) {

      value = operator === '+' || operator === '#' ? encodeReserved(value) : encodeURIComponent(value);

      if (key) {
          return encodeURIComponent(key) + '=' + value;
      } else {
          return value;
      }
  }

  function encodeReserved(str) {
      return str.split(/(%[0-9A-Fa-f]{2})/g).map(function (part) {
          if (!/%[0-9A-Fa-f]/.test(part)) {
              part = encodeURI(part);
          }
          return part;
      }).join('');
  }

  function template (options) {

      var variables = [],
          url = expand(options.url, options.params, variables);

      variables.forEach(function (key) {
          delete options.params[key];
      });

      return url;
  }

  /**
   * Service for URL templating.
   */

  var ie = document.documentMode;
  var el = document.createElement('a');

  function Url(url, params) {

      var self = this || {},
          options = url,
          transform;

      if (isString(url)) {
          options = { url: url, params: params };
      }

      options = merge({}, Url.options, self.$options, options);

      Url.transforms.forEach(function (handler) {
          transform = factory(handler, transform, self.$vm);
      });

      return transform(options);
  }

  /**
   * Url options.
   */

  Url.options = {
      url: '',
      root: null,
      params: {}
  };

  /**
   * Url transforms.
   */

  Url.transforms = [template, query, root];

  /**
   * Encodes a Url parameter string.
   *
   * @param {Object} obj
   */

  Url.params = function (obj) {

      var params = [],
          escape = encodeURIComponent;

      params.add = function (key, value) {

          if (isFunction(value)) {
              value = value();
          }

          if (value === null) {
              value = '';
          }

          this.push(escape(key) + '=' + escape(value));
      };

      serialize(params, obj);

      return params.join('&').replace(/%20/g, '+');
  };

  /**
   * Parse a URL and return its components.
   *
   * @param {String} url
   */

  Url.parse = function (url) {

      if (ie) {
          el.href = url;
          url = el.href;
      }

      el.href = url;

      return {
          href: el.href,
          protocol: el.protocol ? el.protocol.replace(/:$/, '') : '',
          port: el.port,
          host: el.host,
          hostname: el.hostname,
          pathname: el.pathname.charAt(0) === '/' ? el.pathname : '/' + el.pathname,
          search: el.search ? el.search.replace(/^\?/, '') : '',
          hash: el.hash ? el.hash.replace(/^#/, '') : ''
      };
  };

  function factory(handler, next, vm) {
      return function (options) {
          return handler.call(vm, options, next);
      };
  }

  function serialize(params, obj, scope) {

      var array = isArray(obj),
          plain = isPlainObject(obj),
          hash;

      each(obj, function (value, key) {

          hash = isObject(value) || isArray(value);

          if (scope) {
              key = scope + '[' + (plain || hash ? key : '') + ']';
          }

          if (!scope && array) {
              params.add(value.name, value.value);
          } else if (hash) {
              serialize(params, value, key);
          } else {
              params.add(key, value);
          }
      });
  }

  function xdrClient (request) {
      return new Promise$1(function (resolve) {

          var xdr = new XDomainRequest(),
              handler = function (event) {

              var response = request.respondWith(xdr.responseText, {
                  status: xdr.status,
                  statusText: xdr.statusText
              });

              resolve(response);
          };

          request.abort = function () {
              return xdr.abort();
          };

          xdr.open(request.method, request.getUrl(), true);
          xdr.timeout = 0;
          xdr.onload = handler;
          xdr.onerror = handler;
          xdr.ontimeout = function () {};
          xdr.onprogress = function () {};
          xdr.send(request.getBody());
      });
  }

  var ORIGIN_URL = Url.parse(location.href);
  var SUPPORTS_CORS = 'withCredentials' in new XMLHttpRequest();

  function cors (request, next) {

      if (!isBoolean(request.crossOrigin) && crossOrigin(request)) {
          request.crossOrigin = true;
      }

      if (request.crossOrigin) {

          if (!SUPPORTS_CORS) {
              request.client = xdrClient;
          }

          delete request.emulateHTTP;
      }

      next();
  }

  function crossOrigin(request) {

      var requestUrl = Url.parse(Url(request));

      return requestUrl.protocol !== ORIGIN_URL.protocol || requestUrl.host !== ORIGIN_URL.host;
  }

  function body (request, next) {

      if (request.emulateJSON && isPlainObject(request.body)) {
          request.body = Url.params(request.body);
          request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      }

      if (isFormData(request.body)) {
          delete request.headers['Content-Type'];
      }

      if (isPlainObject(request.body)) {
          request.body = JSON.stringify(request.body);
      }

      next(function (response) {

          var contentType = response.headers['Content-Type'];

          if (isString(contentType) && contentType.indexOf('application/json') === 0) {

              try {
                  response.data = response.json();
              } catch (e) {
                  response.data = null;
              }
          } else {
              response.data = response.text();
          }
      });
  }

  function jsonpClient (request) {
      return new Promise$1(function (resolve) {

          var name = request.jsonp || 'callback',
              callback = '_jsonp' + Math.random().toString(36).substr(2),
              body = null,
              handler,
              script;

          handler = function (event) {

              var status = 0;

              if (event.type === 'load' && body !== null) {
                  status = 200;
              } else if (event.type === 'error') {
                  status = 404;
              }

              resolve(request.respondWith(body, { status: status }));

              delete window[callback];
              document.body.removeChild(script);
          };

          request.params[name] = callback;

          window[callback] = function (result) {
              body = JSON.stringify(result);
          };

          script = document.createElement('script');
          script.src = request.getUrl();
          script.type = 'text/javascript';
          script.async = true;
          script.onload = handler;
          script.onerror = handler;

          document.body.appendChild(script);
      });
  }

  function jsonp (request, next) {

      if (request.method == 'JSONP') {
          request.client = jsonpClient;
      }

      next(function (response) {

          if (request.method == 'JSONP') {
              response.data = response.json();
          }
      });
  }

  function before (request, next) {

      if (isFunction(request.before)) {
          request.before.call(this, request);
      }

      next();
  }

  /**
   * HTTP method override Interceptor.
   */

  function method (request, next) {

      if (request.emulateHTTP && /^(PUT|PATCH|DELETE)$/i.test(request.method)) {
          request.headers['X-HTTP-Method-Override'] = request.method;
          request.method = 'POST';
      }

      next();
  }

  function header (request, next) {

      request.method = request.method.toUpperCase();
      request.headers = assign({}, Http.headers.common, !request.crossOrigin ? Http.headers.custom : {}, Http.headers[request.method.toLowerCase()], request.headers);

      next();
  }

  /**
   * Timeout Interceptor.
   */

  function timeout (request, next) {

      var timeout;

      if (request.timeout) {
          timeout = setTimeout(function () {
              request.abort();
          }, request.timeout);
      }

      next(function (response) {

          clearTimeout(timeout);
      });
  }

  function xhrClient (request) {
      return new Promise$1(function (resolve) {

          var xhr = new XMLHttpRequest(),
              handler = function (event) {

              var response = request.respondWith('response' in xhr ? xhr.response : xhr.responseText, {
                  status: xhr.status === 1223 ? 204 : xhr.status, // IE9 status bug
                  statusText: xhr.status === 1223 ? 'No Content' : trim(xhr.statusText),
                  headers: parseHeaders(xhr.getAllResponseHeaders())
              });

              resolve(response);
          };

          request.abort = function () {
              return xhr.abort();
          };

          xhr.open(request.method, request.getUrl(), true);
          xhr.timeout = 0;
          xhr.onload = handler;
          xhr.onerror = handler;

          if (request.progress) {
              if (request.method === 'GET') {
                  xhr.addEventListener('progress', request.progress);
              } else if (/^(POST|PUT)$/i.test(request.method)) {
                  xhr.upload.addEventListener('progress', request.progress);
              }
          }

          if (request.credentials === true) {
              xhr.withCredentials = true;
          }

          each(request.headers || {}, function (value, header) {
              xhr.setRequestHeader(header, value);
          });

          xhr.send(request.getBody());
      });
  }

  function parseHeaders(str) {

      var headers = {},
          value,
          name,
          i;

      each(trim(str).split('\n'), function (row) {

          i = row.indexOf(':');
          name = trim(row.slice(0, i));
          value = trim(row.slice(i + 1));

          if (headers[name]) {

              if (isArray(headers[name])) {
                  headers[name].push(value);
              } else {
                  headers[name] = [headers[name], value];
              }
          } else {

              headers[name] = value;
          }
      });

      return headers;
  }

  function Client (context) {

      var reqHandlers = [sendRequest],
          resHandlers = [],
          handler;

      if (!isObject(context)) {
          context = null;
      }

      function Client(request) {
          return new Promise$1(function (resolve) {

              function exec() {

                  handler = reqHandlers.pop();

                  if (isFunction(handler)) {
                      handler.call(context, request, next);
                  } else {
                      warn('Invalid interceptor of type ' + typeof handler + ', must be a function');
                      next();
                  }
              }

              function next(response) {

                  if (isFunction(response)) {

                      resHandlers.unshift(response);
                  } else if (isObject(response)) {

                      resHandlers.forEach(function (handler) {
                          response = when(response, function (response) {
                              return handler.call(context, response) || response;
                          });
                      });

                      when(response, resolve);

                      return;
                  }

                  exec();
              }

              exec();
          }, context);
      }

      Client.use = function (handler) {
          reqHandlers.push(handler);
      };

      return Client;
  }

  function sendRequest(request, resolve) {

      var client = request.client || xhrClient;

      resolve(client(request));
  }

  var classCallCheck = function (instance, Constructor) {
    if (!(instance instanceof Constructor)) {
      throw new TypeError("Cannot call a class as a function");
    }
  };

  /**
   * HTTP Response.
   */

  var Response = function () {
      function Response(body, _ref) {
          var url = _ref.url;
          var headers = _ref.headers;
          var status = _ref.status;
          var statusText = _ref.statusText;
          classCallCheck(this, Response);


          this.url = url;
          this.body = body;
          this.headers = headers || {};
          this.status = status || 0;
          this.statusText = statusText || '';
          this.ok = status >= 200 && status < 300;
      }

      Response.prototype.text = function text() {
          return this.body;
      };

      Response.prototype.blob = function blob() {
          return new Blob([this.body]);
      };

      Response.prototype.json = function json() {
          return JSON.parse(this.body);
      };

      return Response;
  }();

  var Request = function () {
      function Request(options) {
          classCallCheck(this, Request);


          this.method = 'GET';
          this.body = null;
          this.params = {};
          this.headers = {};

          assign(this, options);
      }

      Request.prototype.getUrl = function getUrl() {
          return Url(this);
      };

      Request.prototype.getBody = function getBody() {
          return this.body;
      };

      Request.prototype.respondWith = function respondWith(body, options) {
          return new Response(body, assign(options || {}, { url: this.getUrl() }));
      };

      return Request;
  }();

  /**
   * Service for sending network requests.
   */

  var CUSTOM_HEADERS = { 'X-Requested-With': 'XMLHttpRequest' };
  var COMMON_HEADERS = { 'Accept': 'application/json, text/plain, */*' };
  var JSON_CONTENT_TYPE = { 'Content-Type': 'application/json;charset=utf-8' };

  function Http(options) {

      var self = this || {},
          client = Client(self.$vm);

      defaults(options || {}, self.$options, Http.options);

      Http.interceptors.forEach(function (handler) {
          client.use(handler);
      });

      return client(new Request(options)).then(function (response) {

          return response.ok ? response : Promise$1.reject(response);
      }, function (response) {

          if (response instanceof Error) {
              error(response);
          }

          return Promise$1.reject(response);
      });
  }

  Http.options = {};

  Http.headers = {
      put: JSON_CONTENT_TYPE,
      post: JSON_CONTENT_TYPE,
      patch: JSON_CONTENT_TYPE,
      delete: JSON_CONTENT_TYPE,
      custom: CUSTOM_HEADERS,
      common: COMMON_HEADERS
  };

  Http.interceptors = [before, timeout, method, body, jsonp, header, cors];

  ['get', 'delete', 'head', 'jsonp'].forEach(function (method) {

      Http[method] = function (url, options) {
          return this(assign(options || {}, { url: url, method: method }));
      };
  });

  ['post', 'put', 'patch'].forEach(function (method) {

      Http[method] = function (url, body, options) {
          return this(assign(options || {}, { url: url, method: method, body: body }));
      };
  });

  function Resource(url, params, actions, options) {

      var self = this || {},
          resource = {};

      actions = assign({}, Resource.actions, actions);

      each(actions, function (action, name) {

          action = merge({ url: url, params: params || {} }, options, action);

          resource[name] = function () {
              return (self.$http || Http)(opts(action, arguments));
          };
      });

      return resource;
  }

  function opts(action, args) {

      var options = assign({}, action),
          params = {},
          body;

      switch (args.length) {

          case 2:

              params = args[0];
              body = args[1];

              break;

          case 1:

              if (/^(POST|PUT|PATCH)$/i.test(options.method)) {
                  body = args[0];
              } else {
                  params = args[0];
              }

              break;

          case 0:

              break;

          default:

              throw 'Expected up to 4 arguments [params, body], got ' + args.length + ' arguments';
      }

      options.body = body;
      options.params = assign({}, options.params, params);

      return options;
  }

  Resource.actions = {

      get: { method: 'GET' },
      save: { method: 'POST' },
      query: { method: 'GET' },
      update: { method: 'PUT' },
      remove: { method: 'DELETE' },
      delete: { method: 'DELETE' }

  };

  function plugin(Vue) {

      if (plugin.installed) {
          return;
      }

      Util(Vue);

      Vue.url = Url;
      Vue.http = Http;
      Vue.resource = Resource;
      Vue.Promise = Promise$1;

      Object.defineProperties(Vue.prototype, {

          $url: {
              get: function () {
                  return options(Vue.url, this, this.$options.url);
              }
          },

          $http: {
              get: function () {
                  return options(Vue.http, this, this.$options.http);
              }
          },

          $resource: {
              get: function () {
                  return Vue.resource.bind(this);
              }
          },

          $promise: {
              get: function () {
                  var _this = this;

                  return function (executor) {
                      return new Vue.Promise(executor, _this);
                  };
              }
          }

      });
  }

  if (typeof window !== 'undefined' && window.Vue) {
      window.Vue.use(plugin);
  }

  return plugin;

}));