---
layout: guide
doc_stub: false
search: true
section: GraphQL Pro
title: Installation
desc: Get started with GraphQL::Pro
index: 1
pro: true
---

`GraphQL::Pro` is distributed as a Ruby gem. When you buy `GraphQL::Pro`, you'll receive credentials, which you can register with bundler:

```sh
bundle config gems.graphql.pro #{YOUR_CREDENTIALS}
```

Then, you can add `graphql-pro` to your Gemfile, which a custom `source`:

```ruby
source "https://gems.graphql.pro" do
  gem "graphql-pro"
end
```

Then, install the gem with Bundler:

```sh
bundle install
```

Then, check out some of `GraphQL::Pro`'s features!

## Updates

To update `GraphQL::Pro`, use Bundler:

```sh
bundle update graphql-pro
```

Be sure to check the [changelog](https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG-pro.md) between versions!

## Dependencies

`graphql-pro 1.0.0` requires `graphql ~>1.4`. The latest version requires `graphql =>1.7.6`.

## Verifying Integrity

You can verify the integrity of `graphql-pro` by getting its checksum and comparing it to the [published checksums](https://github.com/rmosolgo/graphql-ruby/blob/master/guides/pro/checksums).

Include the `graphql:pro:validate` task in your `Rakefile`:

```ruby
# Rakefile
require "graphql/rake_task/validate"
```

Then invoke it with a version:

```
$ bundle exec rake graphql:pro:validate[1.0.0]
Validating graphql-pro v1.0.0
  - Checking for graphql-pro credentials...
    ✓ found
  - Fetching the gem...
    ✓ fetched
  - Validating digest...
    ✓ validated from GitHub
    ✓ validated from graphql-ruby.org
✔ graphql-pro 1.0.0 validated successfully!
```

In case of a failure, please {% open_an_issue "GraphQL Pro installation failure" %}:

```
Validating graphql-pro v1.4.800
  - Checking for graphql-pro credentials...
    ✓ found
  - Fetching the gem...
    ✓ fetched
  - Validating digest...
    ✘ SHA mismatch:
      Downloaded:       c9cab2619aa6540605ce7922784fc84dbba3623383fdce6b17fde01d8da0aff49d666810c97f66310013c030e3ab7712094ee2d8f1ea9ce79aaf65c1684d992a
      GitHub:           404: Not Found
      graphql-ruby.org: 404: Not Found

      This download of graphql-pro is invalid, please open an issue:
      https://github.com/rmosolgo/graphql-ruby/issues/new?title=graphql-pro%20digest%20mismatch%20(1.4.800)
```
