import path from "path"
import fs from "fs"

interface RelayCompilerOperation {
  params?: RelayCompilerOperation
  text: string
  name: string
}
/**
 * Read relay-compiler output
 * and extract info for persisting them & writing a map:
 *
 * - alias: get the relayHash from the header
 * - name: get the name from the JavaScript object
 * - body: get the text from the JavaScript object
 *
 * @param {Array} filenames -  Filenames to read
 * @return {Array} List of operations to persist & write to a map
 */
function prepareRelay(filenames: string[]) {
  var currentDirectory = process.cwd()
  var operations = filenames.map(function(filename) {
    // Search the file for the relayHash
    var textContent = fs.readFileSync(filename, "utf8")
    var operationAlias = textContent.match(/@relayHash ([a-z0-9]+)/)
    // Only operations get `relayHash`, so
    // skip over generated fragments
    if (operationAlias) {
      // Require the file to get values from the JavaScript code
      var absoluteFilename = path.resolve(currentDirectory, filename)
      var operation: RelayCompilerOperation = require(absoluteFilename)
      var operationBody, operationName
      // Support Relay version ^2.0.0
      if (operation.params) {
        operationBody = operation.params.text
        operationName = operation.params.name
      } else {
        // Support Relay versions < 2.0.0
        operationBody = operation.text
        operationName = operation.name
      }

      return {
        alias: operationAlias[1],
        name: operationName,
        body: operationBody,
      }
    } else {
      return {
        alias: "",
        name: "not-found",
        body: "not-found",
      }
    }
  })
  // Remove the nulls
  var operationsWithoutNulls = operations.filter(function(o) { return o.alias.length })
  return operationsWithoutNulls
}

export default prepareRelay
