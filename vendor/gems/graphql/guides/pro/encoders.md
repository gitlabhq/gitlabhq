---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro
title: Encrypted, Versioned Cursors and IDs
desc: Increased opacity and configurability for Relay identifiers
index: 6
pro: true
---

`GraphQL::Pro` includes a mechanism for serving encrypted, versioned cursors and IDs.  This provides some benefits:

- Users can't reverse-engineer node IDs or connection cursors, removing a possible attack vector.
- You can gradually transition between cursor strategies, adding encrypting while supporting any "stale" encoders which clients already have.

`GraphQL::Pro`'s encrypted encoders provide a few security features:

- Key-based encryption by `aes-128-gcm` by default
- Authentication
- Nonces for cursors (but not IDs, that would be silly)

## Defining an Encoder

Encoders can be created by subclassing `GraphQL::Pro::Encoder`: 

```ruby
class MyEncoder < GraphQL::Pro::Encoder
  key("f411f30...")
  # optional:
  tag("81ce51c307")
end
```

- `key` is the encryption key for this encoder. You can generate one with: `require "securerandom"; SecureRandom.bytes(16)`
- `tag`, if provided, is used as authentication data or for disambiguating versioned encoders

## Encrypting Cursors

Encrypt cursors by attaching an encrypted encoder to `Schema#cursor_encoder`:

```ruby
class MySchema GraphQL::Schema
  cursor_encoder(MyCursorEncoder)
end
```

Now, built-in connection implementations will use that encoder for cursors.

If you implement your own connections, you can access the encoder's encryption methods via {{ "GraphQL::Pagination::Connection#encode" | api_doc }} and {{ "GraphQL::Pagination::Connection#decode" | api_doc }}.


## Encrypting IDs

Encrypt IDs by using encoders in `Schema.id_from_object` and `Schema.object_from_id`:

```ruby
class MySchema < GraphQL::Schema
  def self.id_from_object(object, type, ctx)
    id_data = "#{object.class.name}/#{object.id}"
    MyIDEncoder.encode(id_data)
  end

  def self.object_from_id(id, ctx)
    id_data = MyIDEncoder.decode(id)
    class_name, id = id_data.split("/")
    class_name.constantize.find(id)
  end
end
```

Note that IDs are _not_ encrypted with nonces. This means that if someone can _guess_ how IDs are constructed, they can determine the encryption key (a kind of [known-plaintext attack](https://en.wikipedia.org/wiki/Known-plaintext_attack)). To reduce this risk, make your plaintext IDs unpredictable, for example, by appending a salt or obfuscating their content.

## Versioning

You can combine several encoders into a single chain of versioned encoders. Pass them to `.versioned`, newest-to-oldest:

```ruby
# Define some encoders ...
class NewSecureEncoder < GraphQL::Pro::Encoder
  # ...
end

class OldSecureEncoder < GraphQL::Pro::Encoder
  # ...
end

class LegacyInsecureEncoder < GraphQL::Pro::Encoder
  # ...
end

# Then order them by priority:
VersionedEncoder = GraphQL::Pro::Encoder.versioned(
  # Newest:
  NewSecureEncoder,
  OldSecureEncoder,
  # Oldest:
  LegacyInsecureEncoder
)
```

When receiving an ID or cursor, a versioned encoders tries each encoder in sequence. When creating a new ID or cursor, the encoder always uses the first encoder. This way, clients will receiving _new_ encoders, but the server will still accept _old_ encoders (until the old one is removed from the list).

`VersionedEncoder#decode_versioned` returns two values: the decoded data _and_ the encoder which successfully decoded it. You can use this to determine how to process decoded data. For example, you can switch on the encoder:

```ruby
data, encoder = VersionedEncoder.decode_versioned(id)
case encoder
when UUIDEncoder
  find_by_uuid(data)
when SQLPrimaryKeyEncoder
  find_by_pk(data)
when nil
  # `id` could not be decoded
  nil
end
```

## Encoding

By default, encrypted bytes is stringified as base-64. You can specific a custom encoder with the `Encoder#encoder` definition. For example, you could define an encode which uses URL-safe base-64 functions:

```ruby
module URLSafeEncoder
  def self.encode(str)
    Base64.urlsafe_encode64(str)
  end
  def self.decode(str)
    Base64.urlsafe_decode64(str)
  end
end
```

Then attach it to your encoder:

```ruby
class MyURLSafeEncoder < GraphQL::Pro::Encoder
  encoder URLSafeEncoder
end
```

Now, these node IDs and cursors will be URL-safe!
