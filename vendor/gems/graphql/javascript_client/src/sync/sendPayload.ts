import http from "http"
import https from "https"
import url from "url"
import crypto from 'crypto'
import Logger from './logger'

interface SendPayloadOptions {
  url: string,
  logger: Logger,
  secret?: string,
  client?: string,
  headers?: { [key: string]: string },
  changesetVersion?: string,
}
/**
 * Use HTTP POST to send this payload to the endpoint.
 *
 * Override this function with `options.send` to use custom auth.
 *
 * @private
 * @param {Object} payload - JS object to be posted as form data
 * @param {String} options.url - Target URL
 * @param {String} options.secret - (optional) used for HMAC header if provided
 * @param {String} options.client - (optional) used for HMAC header if provided
 * @param {Logger} options.logger - A logger for when `verbose` is true
 * @param {Object<String, String>} options.headers - (optional) extra headers for the request
 * @return {Promise}
*/
function sendPayload(payload: any, options: SendPayloadOptions) {
  var syncUrl = options.url
  var key = options.secret
  var clientName = options.client
  var logger = options.logger
  // Prepare JS object as form data
  var postData = JSON.stringify(payload)

  // Get parts of URL for request options
  var parsedURL = url.parse(syncUrl)

  // Prep options for HTTP request
  var defaultHeaders: {[key: string]: string} = {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData).toString()
  }

  if (options.changesetVersion) {
    logger.log("Changeset Version: ", logger.bright(options.changesetVersion))
    defaultHeaders["Changeset-Version"] = options.changesetVersion
  }
  var allHeaders = Object.assign({}, options.headers, defaultHeaders)

  var httpOptions = {
    protocol: parsedURL.protocol,
    hostname: parsedURL.hostname,
    port: parsedURL.port,
    path: parsedURL.path,
    auth: parsedURL.auth,
    method: 'POST',
    headers: allHeaders,
  };

  // If an auth key was provided, add a HMAC header
  var authDigest = null
  if (key) {
    authDigest = crypto.createHmac('sha256', key)
      .update(postData)
      .digest('hex')
    var header = "GraphQL::Pro " + clientName + " " + authDigest
    httpOptions.headers["Authorization"] = header
  }

  var headerNames = Object.keys(httpOptions.headers)
  logger.log("[Sync] " + headerNames.length + " Headers:")
  headerNames.forEach((headerName) => {
    logger.log("[Sync]    " + headerName + ": " + httpOptions.headers[headerName])
  })
  logger.log("[Sync] Data:", postData)

  var httpClient = parsedURL.protocol === "https:" ? https : http
  var promise = new Promise(function(resolve, reject) {
    // Make the request,
    // hook up response handler
    const req = httpClient.request(httpOptions, (res) => {
      res.setEncoding('utf8');
      // Gather the response from the server
      var body = ""
      res.on('data', (chunk) => {
        body += chunk
      });

      res.on("end", () => {
        logger.log("[Sync] Response Headers: ", JSON.stringify(res.headers))
        logger.log("[Sync] Response Body: ", body)

        var status = res.statusCode
        // 422 gets special treatment because
        // the body has error messages
        if (status && status > 299 && status != 422) {
          reject("  Server responded with " + res.statusCode)
        } else {
          resolve(body)
        }
      })
    });

    req.on('error', (e) => {
      reject(e)
    });

    // Send the data, fire the request
    req.write(postData);
    req.end();
  })

  return promise
}


export default sendPayload
