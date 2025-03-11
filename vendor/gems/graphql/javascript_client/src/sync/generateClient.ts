import { globSync } from "glob"
import prepareRelay from "./prepareRelay"
import prepareIsolatedFiles from './prepareIsolatedFiles'
import prepareProject from "./prepareProject"
import md5 from "./md5"

import generateJs from "./outfileGenerators/js"
import generateJson from "./outfileGenerators/json"

var JS_TYPE = "js";
var JSON_TYPE = "json";

var generators = {
  [JS_TYPE]: generateJs,
  [JSON_TYPE]: generateJson,
};

interface GenerateClientCodeOptions {
  path?: string // A glob to recursively search for `.graphql` files (Default is `./`)
  mode?: string //  If `"file"`, treat each file separately. If `"project"`, concatenate all files and extract each operation. If `"relay"`, treat it as relay-compiler output
  addTypename?: boolean //  Indicates if the "__typename" field are automatically added to your queries
  clientType?: string // The type of the generated code (i.e., json, js)
  client: string // the Client ID that these operations belong to
  hash?: Function // A custom hash function for query strings with the signature `options.hash(string) => digest` (Default is `md5(string) => digest`)
  verbose?: boolean // If true, print debug output
}

interface OperationStoreClient {
  getOperationId: (operationName: string) => string
  getPersistedQueryAlias: (operationName: string) => string
  apolloMiddleware: { applyMiddleware: (req: any, next: any) => any }
  apolloLink: (operation: any, forward: any) => any
}

/**
 * Generate a JavaScript client module based on local `.graphql` files.
 *
 * See {gatherOperations} and {generateClientCode} for options.
 * @return {String} The generated JavaScript code
*/
function generateClient(options: GenerateClientCodeOptions): string {
  var payload = gatherOperations(options)
  var generatedCode = generateClientCode(options.client, payload.operations, options.clientType)
  return generatedCode
}

interface ClientOperation {
  alias: string,
  name?: string,
  body: string,
}
/**
 * Parse files in the specified path and generate an alias for each operation.
*/
function gatherOperations(options: GenerateClientCodeOptions) {
  var graphqlGlob = options.path || "./"
  // Check for file ext already, add it if missing
  var containsFileExt = graphqlGlob.indexOf(".graphql") > -1 || graphqlGlob.indexOf(".gql") > -1
  if (!containsFileExt) {
    graphqlGlob = graphqlGlob + "**/*.graphql*"
  }
  var hashFunc = options.hash || md5
  var filesMode = options.mode || (graphqlGlob.indexOf("__generated__") > -1 ? "relay" : "project")
  var addTypename = !!options.addTypename
  var verbose = !!options.verbose

  var operations: ClientOperation[] = []

  var filenames: string[] = globSync(graphqlGlob, {}).sort()
  if (verbose) {
    console.log("[Sync] glob: ", graphqlGlob)
    console.log("[Sync] " + filenames.length + " files:")
    console.log(filenames.map(function(f) { return "[Sync]   - " + f }).join("\n"))
  }
  if (filesMode == "relay") {
    operations = prepareRelay(filenames)
  } else {
    if (filesMode === "file") {
      operations = prepareIsolatedFiles(filenames, addTypename)
    } else if (filesMode === "project") {
      operations = prepareProject(filenames, addTypename)
    } else {
      throw new Error("Unexpected mode: " + filesMode)
    }
    // Update the operations with the hash of the body
    operations.forEach(function(op) {
      op.alias = hashFunc(op.body)
      // console.log("operation", op.alias, op.body)
    })
  }
  return { operations: operations }
}

/**
 * Given a map of { name => alias } pairs, generate outfile based on type.
 * @param {String} clientName - the client ID that this map belongs to
 * @param {Object} nameToAlias - `name => alias` pairs
 * @param {String} type - the outfile's type
 * @return {String} generated outfile code
*/
function generateClientCode(clientName: string, operations: ClientOperation[], type?: string): string {
  if (!clientName) {
    throw new Error("Client name is required to generate a persisted alias lookup map");
  }

  var nameToAlias: {[key: string] : string | null} = {}
  operations.forEach(function(op) {
    // This can be blank from relay-perisisted-output,
    // but typescript doesn't know that we don't use this function in that case
    // (Er, I should make _two_ interfaces, but I haven't yet.)
    if (op.name) {
      nameToAlias[op.name] = op.alias
    }
  })

  // Build up the map
  var keyValuePairs = "{"
  keyValuePairs += Object.keys(nameToAlias).map(function(operationName) {
    var persistedAlias = nameToAlias[operationName]
    return "\n  \"" + operationName + "\": \"" + persistedAlias + "\""
  }).join(",")
  keyValuePairs += "\n}"

  var outfileType = type || JS_TYPE
  var generateOutfile = generators[outfileType];

  if (!generateOutfile) {
    throw new Error("Unknown generator type " + outfileType + " encountered for generating the outFile");
  }

  return generateOutfile(outfileType, clientName, keyValuePairs);
}

export {
  generateClient,
  generateClientCode,
  gatherOperations,
  JS_TYPE,
  JSON_TYPE,
  ClientOperation,
  OperationStoreClient,
}
