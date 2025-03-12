---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - Defer
title: Overview
desc: What is @defer, and why use it?
index: 0
pro: true
---

`@defer` is a {% internal_link "directive", "/type_definitions/directives" %} for streaming GraphQL responses from the server to the client.

By streaming the response, the server can send the most critical (or most available) data _first_, following up with secondary data shortly afterward.

`@defer` was first described by [Lee Byron at React Europe 2015](https://youtu.be/ViXL0YQnioU?t=768) and got experimental support in [Apollo in 2018](https://blog.apollographql.com/introducing-defer-in-apollo-server-f6797c4e9d6e).

`@stream` is like `@defer`, but it returns list items one at a time. Find details in the {% internal_link "Stream guide", "/defer/stream" %}.

## Example

GraphQL queries can be large and complex, requiring lots of computation or dependencies on slow external services.

In this example, the local server maintains an index of items ("decks"), but the item data ("cards") is actually hosted on a remote server. So, GraphQL queries must make remote calls in order to serve that data.

Without `@defer`, the whole query is blocked until the last field is done resolving:

{{ "https://user-images.githubusercontent.com/2231765/53442028-4a122b00-39d6-11e9-8e33-b91791bf3b98.gif" | link_to_img:"Rails without defer" }}

But, we can add `@defer` to slow fields:

```diff
  deck {
    slots {
      quantity
-     card
+     card @defer {
        name
        price
      }
    }
  }
```

Then, the response will stream to the client bit by bit, so the page can load progressively:

{{ "https://user-images.githubusercontent.com/2231765/53442027-4a122b00-39d6-11e9-8d7b-feb7a4f7962a.gif" | link_to_img:"Rails with defer" }}


This way, clients get a snappy feel from the app even while data is still loading.

View the full demo at https://github.com/rmosolgo/graphql_defer_example.

## Considerations

- `@defer` adds some overhead to the response, so only apply it judiciously.
- `@defer` is single-threaded. `@defer`ed fields are still evaluated in sequence, but in a chunk-by-chunk way.

## Next Steps

{% internal_link "Set up your server", "/defer/setup" %} to support `@defer` or read about {% internal_link "client usage", "/defer/usage" %} of it.
