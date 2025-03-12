# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "graphql/version"
require "date"

Gem::Specification.new do |s|
  s.name        = "graphql"
  s.version     = GraphQL::VERSION
  s.date        = Date.today.to_s
  s.summary     = "A GraphQL language and runtime for Ruby"
  s.description = "A plain-Ruby implementation of GraphQL."
  s.homepage    = "https://github.com/rmosolgo/graphql-ruby"
  s.authors     = ["Robert Mosolgo"]
  s.email       = ["rdmosolgo@gmail.com"]
  s.license     = "MIT"
  s.required_ruby_version = ">= 2.7.0"
  s.metadata    = {
    "homepage_uri" => "https://graphql-ruby.org",
    "changelog_uri" => "https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rmosolgo/graphql-ruby",
    "bug_tracker_uri" => "https://github.com/rmosolgo/graphql-ruby/issues",
    "mailing_list_uri"  => "https://buttondown.email/graphql-ruby",
    "rubygems_mfa_required" => "true",
  }

  s.files = Dir["{lib}/**/*", "MIT-LICENSE", "readme.md", ".yardopts"]

  s.add_runtime_dependency "base64"
  s.add_runtime_dependency "fiber-storage"
  s.add_runtime_dependency "logger"

  s.add_development_dependency "benchmark-ips"
  s.add_development_dependency "concurrent-ruby", "~>1.0"
  s.add_development_dependency "google-protobuf"
  s.add_development_dependency "graphql-batch"
  s.add_development_dependency "memory_profiler"

  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-focus"
  s.add_development_dependency "minitest-reporters"
  s.add_development_dependency "rake"
  s.add_development_dependency 'rake-compiler'
  s.add_development_dependency "rubocop"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "simplecov-lcov"
  s.add_development_dependency "undercover"
  s.add_development_dependency "pronto"
  s.add_development_dependency "pronto-undercover"
  # website stuff
  s.add_development_dependency "jekyll"
  s.add_development_dependency "jekyll-sass-converter", "~>2.2"
  s.add_development_dependency "yard"
  s.add_development_dependency "jekyll-algolia"
  s.add_development_dependency "jekyll-redirect-from"
  s.add_development_dependency "m", "~> 1.5.0"
  s.add_development_dependency "mutex_m"
  s.add_development_dependency "webrick"
end
