var childProcess = require("child_process")
let fs = require('fs')

describe("CLI", () => {
  it("exits 1 on error", () => {
    expect(() => {
      childProcess.execSync("node ./cli.js sync", {stdio: "pipe"})
    }).toThrow("Client name must be provided for sync")
  })

  it("exits 0 on OK", () => {
    childProcess.execSync("node ./cli.js sync -h", {stdio: "pipe"})
  })

  it("runs with some options", () => {
    var buffer = childProcess.execSync("node ./cli.js sync --client=something --header=Abcd:efgh --header=\"Abc: 123 45\" --changeset-version=2023-01-01 --mode=file --path=\"**/doc1.graphql\" --verbose", {stdio: "pipe"})
    var response = buffer.toString().replace(/\033\[[0-9;]*m/g, "")
    expect(response).toEqual("No URL; Generating artifacts without syncing them\n[Sync] glob:  **/doc1.graphql\n[Sync] 1 files:\n[Sync]   - src/__tests__/documents/doc1.graphql\nGenerating client module in src/OperationStoreClient.js...\n✓ Done!\n")
  })

  it("runs with just one header", () => {
    var buffer = childProcess.execSync("node ./cli.js sync --client=something --header=Ab-cd:ef-gh --mode=file --path=\"**/doc1.graphql\"", {stdio: "pipe"})
    var response = buffer.toString().replace(/\033\[[0-9;]*m/g, "")
    expect(response).toEqual("No URL; Generating artifacts without syncing them\nGenerating client module in src/OperationStoreClient.js...\n✓ Done!\n")
  })

  it("writes to a dump file", () => {
    let buffer = childProcess.execSync("node ./cli.js sync --client=something --header=Ab-cd:ef-gh --dump-payload=./DumpPayloadExample.json --path=\"**/doc1.graphql\"", {stdio: "pipe"})
    console.log(buffer.toString())
    let dumpedJSON = fs.readFileSync("./DumpPayloadExample.json", 'utf8')
    expect(dumpedJSON).toEqual(`{
  "operations": [
    {
      "name": "GetStuff",
      "body": "query GetStuff {\\n  stuff\\n}",
      "alias": "b8086942c2fbb6ac69b97cbade848033"
    }
  ]
}
`)
  })

  it("writes to stdout", () => {
    let buffer = childProcess.execSync("node ./cli.js sync --client=something --header=Ab-cd:ef-gh --dump-payload --path=\"**/doc1.graphql\"", {stdio: "pipe"})
    let dumpedJSON = buffer.toString().replace(/\033\[[0-9;]*m/g, "")
    expect(dumpedJSON).toEqual(`{
  "operations": [
    {
      "name": "GetStuff",
      "body": "query GetStuff {\\n  stuff\\n}",
      "alias": "b8086942c2fbb6ac69b97cbade848033"
    }
  ]
}
`)
  })
})
