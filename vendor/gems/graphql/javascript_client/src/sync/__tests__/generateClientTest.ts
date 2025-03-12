import { generateClient } from "../generateClient"

it("returns generated code", function() {
  var code = generateClient({
    path: "./src/__tests__/documents/*.graphql",
    client: "test-client",
  })
  expect(code).toMatchSnapshot()
})
