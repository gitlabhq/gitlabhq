import { generateClientCode, JSON_TYPE } from "../generateClient"

function withExampleClient(callback: (client: string) => void) {
  // Generate some code and write it to a file
  var exampleOperations = [
    {name: "a", alias: "b", body: ""},
    {name: "c-d", alias: "e-f", body: ""}
  ]

  var json = generateClientCode("example-client", exampleOperations, JSON_TYPE)

  // Run callback with generated client
  callback(json)
}

it("generates a valid json object string that maps names to operations", () => {
  withExampleClient((json) => {
    expect(json).toMatchSnapshot() // String version
    expect(JSON.parse(json)).toMatchSnapshot() // Object version (i.e., valid JSON)
  })
})
