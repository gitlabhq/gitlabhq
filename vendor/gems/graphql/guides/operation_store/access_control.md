---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro - OperationStore
title: Access Control
desc: Manage authentication & visibility for your OperationStore server.
index: 6
pro: true
---

The `OperationStore` has a built-in mechanism for authenticating incoming `sync` requests. This way, you can be sure that all registered queries came from legitimate sources.

## Authentication

When you [add a client]({{ site.base_url }}/operation_store/client_workflow#add-a-client), you also associate a _secret_ with that client. You can use the default or provide your own and you can update a client secret at any time. By updating a secret, old secrets become invalid.

This secret is used to add an authorization header, generated with HMAC-SHA256. With this header, the server can assert:

- The request came from an authorized client
- The request was not corrupted in transit

For more info about HMAC, see [Wikipedia](https://en.wikipedia.org/wiki/Hash-based_message_authentication_code) or Ruby's [OpenSSL::HMAC](https://ruby-doc.org/stdlib-2.4.0/libdoc/openssl/rdoc/OpenSSL/HMAC.html) support.

The Authorization header takes the form:

```ruby
"GraphQL::Pro #{client_name} #{hmac}"
```

{% internal_link "graphql-ruby-client", "/javascript_client/sync" %} adds this header to outgoing requests by using the provided `--client` and `--secret` values.
