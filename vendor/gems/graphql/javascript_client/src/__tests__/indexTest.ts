import {sync} from "../index"
import childProcess from "child_process"

describe("root module", () => {
  it("exports the sync function", () => {
    expect(sync).toBeInstanceOf(Function)
  })

  it("exports things at root level", () => {
    // Make sure that the compiled JavaScript
    // has all the expected exports.
    var testScript = "var client = require('./index'); console.log(JSON.stringify({ keys: Object.keys(client).sort() }))"
    var output = childProcess.execSync("node -e \"" + testScript + "\"")
    var outputData = JSON.parse(output.toString())
    var expectedKeys = [
      "AblyLink",
      "ActionCableLink",
      "PusherLink",
      "addGraphQLSubscriptions",
      "createRelaySubscriptionHandler",
      "generateClient",
      "sync"
    ]
    expect(outputData.keys).toEqual(expectedKeys)
  })
})
