---
layout: guide
doc_stub: false
search: true
title: Development
section: Other
desc: Hacking on GraphQL Ruby
---

So, you want to hack on GraphQL Ruby! Here are some tips for getting started.

- [Setup](#setup) your development environment
- [Run the tests](#running-the-tests) to verify your setup
- [Debug](#debugging-with-pry) with pry
- [Run the benchmarks](#running-the-benchmarks) to test performance in your environment
- [Coding guidelines](#coding-guidelines) for working on your contribution
- Special tools for building the [lexer and parser](#lexer-and-parser)
- Building and publishing the [GraphQL Ruby website](#website)
- [Versioning](#versioning) describes how changes are managed and released
- [Releasing](#releasing) Gem versions

## Setup

Get your own copy of graphql-ruby by forking [`rmosolgo/graphql-ruby` on GitHub](https://github.com/rmosolgo/graphql-ruby) and cloning your fork.

Then, install the dependencies:

- Install SQLite3 and MongoDB (eg, `brew install sqlite && brew tap mongodb/brew && brew install mongodb-community`)
- `bundle install`
- `rake compile # If you get warnings at this step, you can ignore them.`
- Optional: [Ragel](https://www.colm.net/open-source/ragel/) is required to build the lexer

## Running the Tests

### Unit tests

You can run the tests with

```
bundle exec rake        # tests & Rubocop
bundle exec rake test   # tests only
```

You can run a __specific file__ with `TEST=`:

```
bundle exec rake test TEST=spec/graphql/query_spec.rb
# run tests in `query_spec.rb` only
```

You can focus on a __specific example__ with `focus`:

```ruby
focus
it "does something cool" do
  # ...
end
```

Then, only `focus`ed tests will run:

```
bundle exec rake test
# only the focused test will be run
```

(This is provided by `minitest-focus`.)

### Integration tests

You need to pick a specific gemfile from gemfiles/ to run integration tests. For example:

```
BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle exec rake test TEST=spec/integration/rails/graphql/relay/array_connection_spec.rb
```

### GraphQL-CParser tests

To test the `graphql_cparser` gem, you have to build the binary first:

```
bundle exec rake build_ext
```

Then, run the test suite with `GRAPHQL_CPARSER=1`:

```
GRAPHQL_CPARSER=1 bundle exec rake test
```

(Add `TEST=` to pick a certain file.)


### Other tests

There are system tests for checking ActionCable behavior, use:

```
bundle exec rake test:system
```

And JavaScript tests:

```
bundle exec rake test:js
```

## Gemfiles, Gemfiles, Gemfiles

`graphql-ruby` has several gemfiles to ensure support for various Rails versions. You can specify a gemfile with `BUNDLE_GEMFILE`, eg:

```
BUNDLE_GEMFILE=gemfiles/rails_5.gemfile bundle exec rake test
```

## Debugging with Pry

[`pry`](https://pryrepl.org/) is included with GraphQL-Ruby's development setup to help with debugging.

To pause execution in Ruby code, add:

```ruby
binding.pry
```

Then, the program will pause and your terminal will become a Ruby REPL. Feel free to use `pry` in your development process!

## Running the Benchmarks

This project includes some Rake tasks to record benchmarks:

```sh
$ bundle exec rake -T | grep bench:
rake bench:profile         # Generate a profile of the introspection query
rake bench:query           # Benchmark the introspection query
rake bench:validate        # Benchmark validation of several queries
```

You can save results by sending the output into a file:

```sh
$ bundle exec rake bench:validate > before.txt
$ cat before.txt
# ...
# --> benchmark output here
```

If you want to check performance, create a baseline by running these tasks before your changes. Then, make your changes and run the tasks again and compare your results.

Keep these points in mind when using benchmarks:

- The results are hardware-specific: computers with different hardware will have different results. So don't compare your results to results from other computers.
- The results are environment-specific: CPU and memory availability are affected by other processes on your computer. So try to create similar environments for your before-and-after testing.

## Coding Guidelines

GraphQL-Ruby uses a thorough test suite to make sure things work reliably day-after-day. Please include tests that describe your changes, for example:

- If you contribute a bug fix, include a test for the code that _was_ broken (and is now fixed)
- If you contribute a feature, include tests for all intended uses of that feature
- If you modify existing behavior, update the tests to cover all intended behaviors for that code

Don't fret about coding style or organization.  There's a minimal Rubocop config in `.rubocop.yml` which runs during CI. You can run it manually with `bundle exec rake rubocop`.

## Website

To update the website, update the `.md` files in `guides/`.

To preview your changes, you can serve the website locally:

```
bundle exec rake site:serve
```

Then visit `http://localhost:4000`.

To publish the website with GitHub pages, run the Rake task:

```
bundle exec rake site:publish
```

### Search Index

GraphQL-Ruby's search index is powered by Algolia. To update the index, you need the API key in an environment variable:

```
$ export ALGOLIA_API_KEY=...
```

Without this key, the search index will fall out-of-sync with the website. Contact @rmosolgo to gain access to this key.

### API Docs

The GraphQL-Ruby website has its own rendered version of the gem's API docs. They're pushed to GitHub pages with a special process.

First, generate local copies of the docs you want to publish:

```
$ bundle exec rake apidocs:gen_version[1.8.0] # for example, generate docs that you want to publish
```

Then, check them out locally:

```
$ bundle exec rake site:serve
# then visit http://localhost:4000/api-doc/1.8.0/
```

Then, publish them as part of the whole site:

```
$ bundle exec rake site:publish
```

Finally, check your work by visiting the docs on the website.

## Versioning

GraphQL-Ruby does _not_ attempt to deliver "semantic versioning" for the reasons described in `jashkenas`'
s post, ["Why Semantic Versioning Isn't"](https://gist.github.com/jashkenas/cbd2b088e20279ae2c8e). Instead, the following scheme is used as a guideline:

- Version numbers consist of three parts, `MAJOR.MINOR.PATCH`
- __`PATCH`__ version indicates bug fixes or small features for specific use cases. Ideally, you can upgrade patch versions with only a quick skim of the changelog.
- __`MINOR`__ version indicates significant additions, internal refactors, or small breaking changes. When upgrading a minor version, check the changelog for any new features or breaking changes which apply to your system. The changelog will always include an upgrade path for any breaking changes. Minor versions may also include deprecation warnings to warn about upcoming breaking changes.
- __`MAJOR`__ version indicates significant breaking changes. Do not expect code to run without some modification, especially if the code yielded deprecation warnings.

This policy is inspired by the [Ruby 2.1.0+ version policy](https://www.ruby-lang.org/en/news/2013/12/21/ruby-version-policy-changes-with-2-1-0/).

Pull requests and issues may be tagged with a [GitHub milestone](https://github.com/rmosolgo/graphql-ruby/milestones) to denote when they'll be released.

The [changelog](https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG.md) should always contain accurate and thorough information so that users can upgrade. If you have trouble upgrading based on the changelog, please open an issue on GitHub.

## Releasing

GraphQL-Ruby doesn't have a strict release schedule. If you think it should, consider opening an issue to share your thoughts.

To cut a release:

- Update `CHANGELOG.md` for the new version:
  - Add a new heading for the new version, and paste the four categories of changes into the new section
  - Open the GitHub milestone corresponding to the new version
  - Check each pull request and put it in the category (or categories) that it belongs in
    - If a change affects the default behavior of GraphQL-Ruby in a disruptive way, add it to `## Breaking Changes` and include migration notes if possible
    - Include the PR number beside the change description for future reference
- Update `lib/graphql/version.rb` with the new version number
- Commit changes to master
- Push changes to GitHub: `git push origin master`. GitHub Actions will update the website.
- Release to RubyGems: `bundle exec rake release`. This will also push the tag to GitHub which will kick off a GitHub Actions job to update the API docs.
- Celebrate 🎊  !
