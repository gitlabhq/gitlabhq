import fs from "fs"
import {parse, visit, print, OperationDefinitionNode} from "graphql"
import {addTypenameIfAbsent} from "./addTypenameToSelectionSet"
import { removeClientFields } from "./removeClientFields"

/**
 * Read a bunch of GraphQL files and treat them as islands.
 * Don't join any fragments from other files.
 * Don't make assertions about name uniqueness.
 *
 */
function prepareIsolatedFiles(filenames: string[], addTypename: boolean) {
  return filenames.map(function(filename) {
    var fileOperationBody = fs.readFileSync(filename, "utf8")
    var fileOperationName = ""

    var ast = parse(fileOperationBody)
    var visitor = {
      OperationDefinition: {
        enter: function(node: OperationDefinitionNode) {
          if (fileOperationName.length > 0) {
            throw new Error("Found multiple operations in " + filename + ": " + fileOperationName + ", " + node.name + ". Files must contain only one operation")
          } else if (node.name && node.name.value) {
            fileOperationName = node.name.value
          }
        },
      },
      InlineFragment: {
        leave: addTypename ? addTypenameIfAbsent : () => {}
      },
      Field: {
        leave: addTypename ? addTypenameIfAbsent : () => {}
      }
    }
    ast = visit(ast, visitor)
    ast = removeClientFields(ast)

    return {
      // populate alias later, when hashFunc is available
      alias: "",
      name: fileOperationName,
      body: print(ast),
    }
  })
}

export default prepareIsolatedFiles
