---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - Defer
title: Use with GraphiQL
desc: Using @defer with the GraphiQL IDE
index: 4
pro: true
---

You can use `@defer` and `@stream` with [GraphiQL](https://github.com/graphql/graphiql/blob/main/packages/graphiql/README.md), an in-browser IDE.

<img src="/defer/defer-graphiql-gif.gif"  alt="Using @defer with GraphiQL" style="max-width: 100%" />

## Incremental responses

If you're using the proposed `incremental: ...` response syntax ([proposal](https://github.com/graphql/graphql-spec/pull/742), [Ruby support](/defer/setup.html#example-rails-with-apollo-client)), you'll need a custom "fetcher" function to handle the `incremental: ...` part of the response. For example:

```js
import { meros } from "meros"; // for handling multipart responses

const customFetcher = async function* (graphqlParams, fetcherOpts) {
  // Make the initial fetch
  var result = await fetch("/graphql", {
    method: "POST",
    body: JSON.stringify(graphqlParams),
    headers: {
      'content-type': 'application/json',
    }
  }).then((r) => {
    // Use meros to turn multipart responses into streams
    return meros(r, { multiple: true })
  })

  if (!isAsyncIterable(result)) {
    // Return plain responses as promises
    return result.json()
  } else {
    // Handle multipart responses one chunk at a time
    for await (const chunk of result) {
      yield chunk.map(part => {
        // Move the incremental part of the response into top-level
        // This assumes there's only one `incremental` entry
        // which is currently true for GraphQL-Pro's @defer implementation
        var newJson = {...part.body}
        if (newJson.incremental) {
          newJson.data = newJson.incremental[0].data
          newJson.path = newJson.incremental[0].path
          delete newJson.incremental
        }
        return newJson
      });
    }
  }
}

// Helper for checking for a multipart response:
function isAsyncIterable(input) {
  return (
      typeof input === "object" &&
      input !== null &&
      (
        input[Symbol.toStringTag] === "AsyncGenerator" ||
        (Symbol.asyncIterator && Symbol.asyncIterator in input)
      )
    );
}

```

Hopefully a new GraphiQL version will support this out of the box; follow the [issue on GitHub](https://github.com/graphql/graphiql/issues/3470).
