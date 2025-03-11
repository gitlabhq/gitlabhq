import preparePersistedQueryList from "../preparePersistedQueryList"

it("reads generate-persisted-query-manifest output", () => {
  const manifestPath = "./src/sync/__tests__/generate-persisted-query-manifest.json"
  var ops = preparePersistedQueryList(manifestPath)
  expect(ops).toMatchSnapshot()
})
