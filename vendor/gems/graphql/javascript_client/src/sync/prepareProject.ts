import { addTypenameIfAbsent } from "./addTypenameToSelectionSet";
import fs from "fs"
import {parse, visit, print, OperationDefinitionNode, FragmentDefinitionNode, FragmentSpreadNode, DocumentNode} from "graphql"
import { removeClientFields } from "./removeClientFields";

/**
 * Take a whole bunch of GraphQL in one big string
 * and validate it, especially:
 *
 * - operation names are unique
 * - fragment names are unique
 *
 * Then, split each operation into a free-standing document,
 * so it has all the fragments it needs.
 */

function prepareProject(filenames: string[], addTypename: boolean) {
  if(!filenames.length) { return []; }
  var allGraphQL = ""
  filenames.forEach(function(filename) {
    allGraphQL += fs.readFileSync(filename)
  })

  var ast = parse(allGraphQL)

  // This will contain { name: [name, name] } pairs
  var definitionDependencyNames: {[key: string] : string[] } = {}
  var allOperationNames: string[] = []
  var currentDependencyNames = null

  // When entering a fragment or operation,
  // start recording its dependencies
  var enterDefinition = function(node: FragmentDefinitionNode | OperationDefinitionNode) {
    // Technically, it could be an anonymous definition
    if (node.name) {
      var definitionName = node.name.value
      if (definitionDependencyNames[definitionName]) {
        throw new Error("Found duplicate definition name: " + definitionName + ", fragment & operation names must be unique to sync")
      } else {
        currentDependencyNames = definitionDependencyNames[definitionName] = []
      }
    }
  }

  var visitor = {
    OperationDefinition: {
      enter: function(node: OperationDefinitionNode) {
        enterDefinition(node)
        node.name && allOperationNames.push(node.name.value)
      },
    },
    FragmentDefinition: {
      enter: enterDefinition,
    },
    // When entering a fragment spread, register it as a
    // dependency of its context
    FragmentSpread: {
      enter: function(node: FragmentSpreadNode) {
        currentDependencyNames.push(node.name.value)
      }
    },
    Field: {
      leave: addTypename ? addTypenameIfAbsent : () => {}
    },
    InlineFragment: {
      leave: addTypename ? addTypenameIfAbsent : () => {}
    }
  }

  // Find the dependencies, build the accumulator
  ast = visit(ast, visitor)
  ast = removeClientFields(ast)
  // For each operation, build a separate document of that operation and its deps
  // then print the new document to a string
  var operations = allOperationNames.map(function(operationName) {
    var visitedDepNames: string[] = []
    var depNamesToVisit = [operationName]

    var depName
    while (depNamesToVisit.length > 0) {
      depName = depNamesToVisit.shift()
      if (depName) {
        visitedDepNames.push(depName)
        definitionDependencyNames[depName].forEach(function(nextDepName) {
          if (visitedDepNames.indexOf(nextDepName) === -1) {
            depNamesToVisit.push(nextDepName)
          }
        })
      }
    }
    var newAST = extractDefinitions(ast, visitedDepNames)
    return {
      name: operationName,
      body: print(newAST),
      alias: "", // will be filled in later, when hashFunc is available
    }
  })

  return operations
}


// Return a new AST which contains only `definitionNames`
function extractDefinitions(ast: DocumentNode, definitionNames: string[]) {
  var removeDefinitionNode = function(node: FragmentDefinitionNode | OperationDefinitionNode) {
    if (node.name && definitionNames.indexOf(node.name.value) === -1) {
      return null
    } else {
      return undefined
    }
  }
  var visitor = {
    OperationDefinition: removeDefinitionNode,
    FragmentDefinition: removeDefinitionNode,
  }

  var newAST = visit(ast, visitor)
  return newAST
}

export default prepareProject
