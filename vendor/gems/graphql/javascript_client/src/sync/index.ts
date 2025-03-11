import sendPayload from "./sendPayload"
import dumpPayload from "./dumpPayload"
import { generateClientCode, gatherOperations, ClientOperation } from "./generateClient"
import Logger from "./logger"
import fs from "fs"
import { removeClientFieldsFromString } from "./removeClientFields"
import preparePersistedQueryList from "./preparePersistedQueryList"

export interface SyncOptions {
  path?: string,
  relayPersistedOutput?: string,
  apolloAndroidOperationOutput?: string,
  apolloCodegenJsonOutput?: string,
  apolloPersistedQueryManifest?: string,
  secret?: string
  url?: string,
  mode?: string,
  dumpPayload?: string | true,
  outfile?: string,
  outfileType?: string,
  client: string,
  send?: Function,
  hash?: Function,
  verbose?: boolean,
  quiet?: boolean,
  addTypename?: boolean,
  changesetVersion?: string,
  headers?: {[key: string]: string},
}
/**
 * Find `.graphql` files in `path`,
 * then prepare them & send them to the configured endpoint.
 *
 * @param {Object} options
 * @param {String} options.path - A glob to recursively search for `.graphql` files (Default is `./`)
 * @param {String} options.relayPersistedOutput - A path to a `.json` file from `relay-compiler`'s  `--persist-output` option
 * @param {String} options.apolloCodegenJsonOutput - A path to a `.json` file from `apollo client:codegen ... --type json`
 * @param {String} options.apolloPersistedQueryManifest - A path to a `.json` file from `generate-persisted-query-manifest`
 * @param {String} options.secret - HMAC-SHA256 key which must match the server secret (default is no encryption)
 * @param {String} options.url - Target URL for sending prepared queries. If omitted, then an outfile is generated without sending operations to the server.
 * @param {String} options.mode - If `"file"`, treat each file separately. If `"project"`, concatenate all files and extract each operation. If `"relay"`, treat it as relay-compiler output
 * @param {Boolean} options.addTypename - Indicates if the "__typename" field are automatically added to your queries
 * @param {String} options.outfile - Where the generated code should be written
 * @param {String} options.outfileType - The type of the generated code (i.e., json, js)
 * @param {String} options.client - the Client ID that these operations belong to
 * @param {Function} options.send - A function for sending the payload to the server, with the signature `options.send(payload)`. (Default is an HTTP `POST` request)
 * @param {Function} options.hash - A custom hash function for query strings with the signature `options.hash(string) => digest` (Default is `md5(string) => digest`)
 * @param {Boolean} options.verbose - If true, log debug output
 * @param {Object<String, String>} options.headers - If present, extra headers to add to the HTTP request
 * @param {String|true} options.dumpPayload - If a filename is given, write the HTTP Post data to that file. If present without a filename, print it to stdout.
 * @param {String} options.changesetVersion - If present, sent to populate `context[:changeset_version]` on the server
 * @return {Promise} Rejects with an Error or String if something goes wrong. Resolves with the operation payload if successful.
*/
function sync(options: SyncOptions) {
  var logger = new Logger(!!options.quiet)
  var verbose = !!options.verbose
  var url = options.url
  var dumpingPayload = "dumpPayload" in options
  var dumpingToStdout = options.dumpPayload == true
  if (!url && !dumpingPayload) {
    logger.log("No URL; Generating artifacts without syncing them")
  }
  var clientName = options.client
  if (!clientName) {
    throw new Error("Client name must be provided for sync")
  }
  var encryptionKey = options.secret
  if (encryptionKey && options.dumpPayload != null) {
    logger.log("Authenticating with HMAC")
  }

  var graphqlGlob = options.path
  var hashFunc = options.hash
  var sendFunc = options.send || (dumpingPayload ? dumpPayload : sendPayload)
  var gatherMode = options.mode
  var clientType = options.outfileType
  if (options.relayPersistedOutput) {
    // relay-compiler has already generated an artifact for us
    var payload: { operations: ClientOperation[] } = { operations: [] }
    var relayOutputText = fs.readFileSync(options.relayPersistedOutput, "utf8")
    var relayOutput = JSON.parse(relayOutputText)
    var operationBody
    for (var hash in relayOutput) {
      operationBody = relayOutput[hash]
      payload.operations.push({
        body: operationBody,
        alias: hash,
      })
    }
  } else if (options.apolloAndroidOperationOutput) {
    // Apollo Android has already generated an artifact (https://www.apollographql.com/docs/android/advanced/persisted-queries/#operationoutputjson)
    var payload: { operations: ClientOperation[] } = { operations: [] }
    var apolloAndroidOutputText = fs.readFileSync(options.apolloAndroidOperationOutput, "utf8")
    var apolloAndroidOutput = JSON.parse(apolloAndroidOutputText)
    var operationData
    // Structure is { operationId => { "name" => "...", "source" => "query { ... } " } }
    for (var operationId in apolloAndroidOutput) {
      operationData = apolloAndroidOutput[operationId]
      let bodyWithoutClientFields = removeClientFieldsFromString(operationData.source)
      payload.operations.push({
        body: bodyWithoutClientFields,
        alias: operationId,
      })
    }
  } else if (options.apolloCodegenJsonOutput)  {
    var payload: { operations: ClientOperation[] } = { operations: [] }
    const jsonText = fs.readFileSync(options.apolloCodegenJsonOutput).toString()
    const jsonData = JSON.parse(jsonText)
    jsonData.operations.map(function(operation: {operationId: string, operationName: string, sourceWithFragments: string}) {
      const bodyWithoutClientFields = removeClientFieldsFromString(operation.sourceWithFragments)
      payload.operations.push({
        alias: operation.operationId,
        name: operation.operationName,
        body: bodyWithoutClientFields,
      })
    })
  } else if (options.apolloPersistedQueryManifest) {
    var payload: { operations: ClientOperation[] } = {
      operations: preparePersistedQueryList(options.apolloPersistedQueryManifest)
    }
  } else {
    var payload = gatherOperations({
      path: graphqlGlob,
      hash: hashFunc,
      mode: gatherMode,
      addTypename: !!options.addTypename,
      clientType: clientType,
      client: clientName,
      verbose: verbose,
    })
  }

  var outfile: string | null
  if (options.outfile) {
    outfile = options.outfile
  } else if (options.relayPersistedOutput || options.apolloAndroidOperationOutput || options.apolloCodegenJsonOutput || options.apolloPersistedQueryManifest) {
    // These artifacts have embedded IDs in its generated files,
    // no need to generate an outfile.
    outfile = null
  } else if (fs.existsSync("src")) {
    outfile = "src/OperationStoreClient.js"
  } else {
    outfile = "OperationStoreClient.js"
  }

  var syncPromise = new Promise(function(resolve, reject) {
    if (payload.operations.length === 0) {
      logger.log("No operations found in " + options.path + ", not syncing anything")
      resolve(null)
      return
    } else if (url) {
      logger.log("Syncing " + payload.operations.length + " operations to " + logger.bright(url) + "...")
      var sendOpts = {
        url: url,
        client: clientName,
        secret: encryptionKey,
        headers: options.headers,
        changesetVersion: options.changesetVersion,
        logger: logger,
      }
      var sendPromise = Promise.resolve(sendFunc(payload, sendOpts))
      return sendPromise.then(function(response) {
        var responseData
        if (response) {
          try {
            responseData = JSON.parse(response)
            var aliasToNameMap: {[key: string] : string | undefined} = {}

            payload.operations.forEach(function(op) {
              aliasToNameMap[op.alias] = op.name
            })

            var failed = responseData.failed.length
            // These might get overridden for status output
            var notModified = responseData.not_modified.length
            var added = responseData.added.length
            if (failed) {
              // Override these to reflect reality
              notModified = 0
              added = 0
            }

            var addedColor = added ? "green" : "dim"
            logger.log("  " + logger.colorize(addedColor, added + " added"))
            var notModifiedColor = notModified ? "reset" : "dim"

            logger.log("  " + logger.colorize(notModifiedColor, notModified + " not modified"))
            var failedColor = failed ? "red" : "dim"
            logger.log("  " + logger.colorize(failedColor, failed + " failed"))

            if (failed) {
              logger.error("Sync failed, errors:")
              var failedOperationAlias: string
              var failedOperationName: string
              var errors
              var allErrors: string[] = []
              for (failedOperationAlias in responseData.errors) {
                failedOperationName = aliasToNameMap[failedOperationAlias] || failedOperationAlias
                logger.error("  " + failedOperationName + ":")
                errors = responseData.errors[failedOperationAlias]
                errors.forEach(function(errMessage: string) {
                  allErrors.push(failedOperationName + ": " + errMessage)
                  logger.error("    " + logger.red("✘") + " " + errMessage)
                })
              }
              reject("Sync failed: " + allErrors.join(", "))
              return
            }
          } catch (err) {
            logger.log("Failed to print sync result:", err as string)
            reject(err)
            return
          }
        }
        resolve(payload)
        return
      }).catch(function(err) {
        logger.error(logger.red("Sync failed:"))
        logger.error(err)
        reject(err)
        return
      })
    } else if (dumpingPayload) {
      sendFunc(payload, { dumpPayload: options.dumpPayload })
      resolve(payload)
      return
    } else {
      // This is a local-only run to generate an artifact
      resolve(payload)
      return
    }
  })

  return syncPromise.then(function(_payload) {
    // The payload is yielded when sync was successful, but typescript had
    // trouble using it from ^^ here. So instead, just use its presence as a signal to continue.

    // Don't generate a new file when we're using relay-compiler's --persist-output
    if (_payload && outfile) {
      var generatedCode = generateClientCode(clientName, payload.operations, clientType)
      var finishedPayload = {
        operations: payload.operations,
        generatedCode,
      }
      if (!dumpingToStdout) {
        logger.log("Generating client module in " + logger.colorize("bright", outfile) + "...")
      }
      fs.writeFileSync(outfile, generatedCode, "utf8")
      if (!dumpingToStdout) {
        logger.log(logger.green("✓ Done!"))
      }
      return finishedPayload
    } else {
      if (!dumpingToStdout) {
        logger.log(logger.green("✓ Done!"))
      }
      return payload
    }
  })
}

export default sync
