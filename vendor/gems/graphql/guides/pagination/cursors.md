---
layout: guide
doc_stub: false
search: true
section: Pagination
title: Cursors
desc: Advancing through lists with opaque cursors
index: 4
---

Connections use _cursors_ to advance through paginated lists. A cursor is an opaque string that indicates a specific point in this.

Here, _opaque_ means that the string has no meaning except its value. cursors shouldn't be decoded, reverse-engineered, or generated ad-hoc. The only guarantee of a cursor is that, after you retrieve one, you can use it to request subsequent or preceding items in the list.

Although cursors can be tricky, they were chosen for Relay-style connections because they can be implemented in stable and high-performing ways.

## Customizing Cursors

By default, cursors are encoded in base64 to make them opaque to a human client. You can specify a custom encoder with `Schema.cursor_encoder`. The value should be an object which responds to `.encode(plain_text, nonce:)` and `.decode(encoded_text, nonce: false)`.

For example, to use URL-safe base-64 encoding:

```ruby
module URLSafeBase64Encoder
  def self.encode(txt, nonce: false)
    Base64.urlsafe_encode64(txt)
  end

  def self.decode(txt, nonce: false)
    Base64.urlsafe_decode64(txt)
  end
end

class MySchema < GraphQL::Schema
  # ...
  cursor_encoder(URLSafeBase64Encoder)
end
```

Now, all connections will use URL-safe base-64 encoding.

From a connection instance, the `cursor_encoders` methods are available via {{ "GraphQL::Pagination::Connection#encode" | api_doc }} and {{ "GraphQL::Pagination::Connection#decode" | api_doc }}
