import fs from "fs"

// Transform the output from generate-persisted-query-manifest
// to something that OperationStore `sync` can use.
export default function preparePersistedQueryList(pqlPath: string) {
  const pqlString = fs.readFileSync(pqlPath, "utf8")
  const pqlJson = JSON.parse(pqlString)
  return pqlJson.operations.map(function(persistedQueryConfig: { body: string, id: string, name: string, type: string }) {
    return {
      body: persistedQueryConfig.body,
      alias: persistedQueryConfig.id,
      name: persistedQueryConfig.name
    }
  })
}
