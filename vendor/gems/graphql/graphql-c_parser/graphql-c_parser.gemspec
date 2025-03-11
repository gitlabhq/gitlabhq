# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "graphql/c_parser/version"
require "date"

Gem::Specification.new do |s|
  s.name        = "graphql-c_parser"
  s.version     = GraphQL::CParser::VERSION
  s.date        = Date.today.to_s
  s.summary     = "A parser for GraphQL, implemented as a C extension"
  s.homepage    = "https://github.com/rmosolgo/graphql-ruby"
  s.authors     = ["Robert Mosolgo"]
  s.email       = ["rdmosolgo@gmail.com"]
  s.license     = "MIT"
  s.required_ruby_version = ">= 3.0.0"
  s.metadata    = {
    "homepage_uri" => "https://graphql-ruby.org",
    "changelog_uri" => "https://github.com/rmosolgo/graphql-ruby/blob/master/graphql-c_parser/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rmosolgo/graphql-ruby",
    "bug_tracker_uri" => "https://github.com/rmosolgo/graphql-ruby/issues",
    "mailing_list_uri"  => "https://buttondown.email/graphql-ruby",
  }

  s.files = Dir["{lib,ext}/**/*.{rb,h,c}"]
  s.extensions << "ext/graphql_c_parser_ext/extconf.rb"
  s.add_dependency "graphql", ">= 2.2.10"
end
