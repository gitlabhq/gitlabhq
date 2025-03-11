#!/usr/bin/env node
import parseArgs from "minimist"
import sync, { SyncOptions } from "./sync/index"
var argv = parseArgs(process.argv.slice(2))

if (argv.help || argv.h) {
  console.log(`usage: graphql-ruby-client sync <options>

  Read .graphql files and push the contained
  operations to a GraphQL::Pro::OperationStore

required arguments:
  --url=<endpoint-url>    URL where data should be POSTed
  --client=<client-name>  Identifier for this client application

optional arguments:
  --path=<path>                             Path to .graphql files (default is "./**/*.graphql")
  --outfile=<generated-filename>            Target file for generated code
  --outfile-type=<type>                     Target type for generated code (default is "js")
  --secret=<secret>                         HMAC authentication key
  --relay-persisted-output=<path>           Path to a .json file from "relay-compiler ... --persist-output"
                                              (Outfile generation is skipped by default.)
  --apollo-codegen-json-output=<path>       Path to a .json file from "apollo client:codegen ... --target json"
                                              (Outfile generation is skipped by default.)
  --apollo-android-operation-output=<path>  Path to a .json file from Apollo-Android's "generateOperationOutput" feature.
                                              (Outfile generation is skipped by default.)
  --apollo-persisted-query-manifest=<path>  Path to a .json file from Apollo's "generate-persisted-query-manifest" tool.
                                              (Outfile generation is skipped by default.)
  --mode=<mode>                             Treat files like a certain kind of project:
                                              relay: treat files like relay-compiler output
                                              project: treat files like a cohesive project (fragments are shared, names must be unique)
                                              file: treat each file like a stand-alone operation

                                            By default, this flag is set to:
                                              - "relay" if "__generated__" in the path
                                              - otherwise, "project"
  --header=<header>:<value>                 Add a header to the outgoing HTTP request
                                              (may be repeated)
  --changeset-version=<version>             Populates \`context[:changeset_version]\` for this sync (for the GraphQL-Enterprise "Changesets" feature)
  --add-typename                            Automatically adds the "__typename" field to your queries
  --dump-payload=<filename>                 Print the HTTP Post data to this file, or to stdout if no filename is given
  --quiet                                   Suppress status logging
  --verbose                                 Print debug output
  --help                                    Print this message
`)
} else {
  var commandName = argv._[0]

  if (commandName !== "sync") {
    console.log("Only `graphql-ruby-client sync` is supported")
  } else {
    var parsedHeaders: {[key: string]: string} = {}
    if (argv.header) {
      if (typeof(argv.header) === "string") {
        var headerParts = argv.header.split(":")
        parsedHeaders[headerParts[0]] = headerParts[1]
      } else {
        argv.header.forEach((h: string) => {
          var headerParts = h.split(":")
          parsedHeaders[headerParts[0]] = headerParts[1]
        })
      }
    }
    let syncOptions: SyncOptions = {
      path: argv.path,
      relayPersistedOutput: argv["relay-persisted-output"],
      apolloCodegenJsonOutput: argv["apollo-codegen-json-output"],
      apolloAndroidOperationOutput: argv["apollo-android-operation-output"],
      apolloPersistedQueryManifest: argv["apollo-persisted-query-manifest"],
      url: argv.url,
      client: argv.client,
      outfile: argv.outfile,
      outfileType: argv["outfile-type"],
      secret: argv.secret,
      mode: argv.mode,
      headers: parsedHeaders,
      addTypename: argv["add-typename"],
      quiet: argv.hasOwnProperty("quiet"),
      verbose: argv.hasOwnProperty("verbose"),
      changesetVersion: argv["changeset-version"],
    }

    if ("dump-payload" in argv) {
      syncOptions.dumpPayload = argv["dump-payload"]
    }

    var result = sync(syncOptions)

    result.then(function() {
      process.exit(0)
    }).catch(function() {
      // The error is logged by the function
      process.exit(1)
    })
  }
}
