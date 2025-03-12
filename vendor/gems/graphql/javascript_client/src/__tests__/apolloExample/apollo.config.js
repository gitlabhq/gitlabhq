// apollo client:codegen gen/output.json --target json
module.exports = {
  client: {
    service: {
      name: "testSchema",
      localSchemaFile: "./schema.graphql",
    },
    includes: ["./*.ts"],
    mergeInFieldsFromFragmentSpreads: true,
  }
}
