import dumpPayload from "../dumpPayload"
import fs from 'fs'
interface MockedObject {
  mock: { calls: object }
}

describe("printing out the HTTP Post payload", () => {
  beforeEach(() => {
    process.stdout.write = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks();
  })


  it("prints the result to stdout", () => {
    var spy = (process.stdout.write as unknown) as MockedObject
    dumpPayload({"ok": { "1": true}}, { dumpPayload: true })
    expect(spy.mock.calls).toMatchSnapshot()
  })

  it("writes the result to a file", () => {
    dumpPayload({"ok": { "1": true}}, {dumpPayload: "./DumpPayloadExample.json"})
    let writtenContents = fs.readFileSync("./DumpPayloadExample.json", 'utf8')
    expect(writtenContents).toEqual(`{
  "ok": {
    "1": true
  }
}
`)
  })
})
