# frozen_string_literal: true
require "bundler/gem_helper"
Bundler::GemHelper.install_tasks

require "rake/testtask"
require_relative "guides/_tasks/site"
require_relative "lib/graphql/rake_task/validate"
require 'rake/extensiontask'

Rake::TestTask.new do |t|
  t.libs << "spec" << "lib" << "graphql-c_parser/lib"

  exclude_integrations = []
  ['mongoid', 'rails'].each do |integration|
    begin
      require integration
    rescue LoadError
      exclude_integrations << integration
    end
  end

  t.test_files = FileList.new("spec/**/*_spec.rb") do |fl|
    fl.exclude(*exclude_integrations.map { |int| "spec/integration/#{int}/**/*" })
  end

  # After 2.7, there were not warnings for uninitialized ivars anymore
  if RUBY_VERSION < "3"
    t.warning = false
  end
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

default_tasks = [:test, :rubocop]
if ENV["SYSTEM_TESTS"]
  task(default: ["test:system"] + default_tasks)
else
  task(default: default_tasks)
end

def assert_dependency_version(dep_name, required_version, check_script)
  version = `#{check_script}`
  if !version.include?(required_version)
    raise <<-ERR
build_parser requires #{dep_name} version "#{required_version}", but found:

  $ #{check_script}
  > #{version}

To fix this issue:

- Update #{dep_name} to the required version
- Update the assertion in `Rakefile` to match the current version
ERR
  end
end

namespace :bench do
  def prepare_benchmark
    $LOAD_PATH << "./lib" << "./spec/support"
    require_relative("./benchmark/run.rb")
  end

  desc "Benchmark parsing"
  task :parse do
    prepare_benchmark
    GraphQLBenchmark.run("parse")
  end

  desc "Benchmark lexical analysis"
  task :scan do
    prepare_benchmark
    GraphQLBenchmark.run("scan")
  end

  desc "Benchmark the introspection query"
  task :query do
    prepare_benchmark
    GraphQLBenchmark.run("query")
  end

  desc "Benchmark validation of several queries"
  task :validate do
    prepare_benchmark
    GraphQLBenchmark.run("validate")
  end

  desc "Profile a validation"
  task :validate_memory do
    prepare_benchmark
    GraphQLBenchmark.validate_memory
  end

  desc "Generate a profile of the introspection query"
  task :profile do
    prepare_benchmark
    GraphQLBenchmark.profile
  end

  desc "Run benchmarks on a very large result"
  task :profile_large_result do
    prepare_benchmark
    GraphQLBenchmark.profile_large_result
  end

  desc "Run benchmarks on a small result"
  task :profile_small_result do
    prepare_benchmark
    GraphQLBenchmark.profile_small_result
  end

  desc "Run introspection on a small schema"
  task :profile_small_introspection do
    prepare_benchmark
    GraphQLBenchmark.profile_small_introspection
  end

  desc "Dump schema to SDL"
  task :profile_to_definition do
    prepare_benchmark
    GraphQLBenchmark.profile_to_definition
  end

  desc "Load schema from SDL"
  task :profile_from_definition do
    prepare_benchmark
    GraphQLBenchmark.profile_from_definition
  end

  desc "Compare GraphQL-Batch and GraphQL-Dataloader"
  task :profile_batch_loaders do
    prepare_benchmark
    GraphQLBenchmark.profile_batch_loaders
  end

  desc "Run benchmarks on schema creation"
  task :profile_boot do
    prepare_benchmark
    GraphQLBenchmark.profile_boot
  end

  desc "Check the memory footprint of a large schema"
  task :profile_schema_memory_footprint do
    prepare_benchmark
    GraphQLBenchmark.profile_schema_memory_footprint
  end

  desc "Check the depth of the stacktrace during execution"
  task :profile_stack_depth do
    prepare_benchmark
    GraphQLBenchmark.profile_stack_depth
  end

  desc "Run a very big introspection query"
  task :profile_large_introspection do
    prepare_benchmark
    GraphQLBenchmark.profile_large_introspection
  end

  task :profile_small_query_on_large_schema do
    prepare_benchmark
    GraphQLBenchmark.profile_small_query_on_large_schema
  end

  desc "Run analysis on a big query"
  task :profile_large_analysis do
    prepare_benchmark
    GraphQLBenchmark.profile_large_analysis
  end

  desc "Run analysis on parsing"
  task :profile_parse do
    prepare_benchmark
    GraphQLBenchmark.profile_parse
  end
end

namespace :test do
  desc "Run system tests for ActionCable subscriptions"
  task :system do
    success = Dir.chdir("spec/dummy") do
      system("bundle install")
      system("bundle exec bin/rails test:system")
    end
    success || abort
  end

  task js: "js:test"
end

namespace :js do
  client_dir = "./javascript_client"

  desc "Run the tests for javascript_client"
  task :test do
    success = Dir.chdir(client_dir) do
      system("yarn run test")
    end
    success || abort
  end

  desc "Install JS dependencies"
  task :install do
    Dir.chdir(client_dir) do
      system("yarn install")
    end
  end

  desc "Compile TypeScript to JavaScript"
  task :build do
    Dir.chdir(client_dir) do
      system("yarn tsc")
    end
  end
  task all: [:install, :build, :test]
end

task :build_c_lexer do
  assert_dependency_version("Ragel", "7.0.4", "ragel -v")
  `ragel -F1 graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl`
end

Rake::ExtensionTask.new("graphql_c_parser_ext") do |t|
  t.ext_dir = 'graphql-c_parser/ext/graphql_c_parser_ext'
  t.lib_dir = "graphql-c_parser/lib/graphql"
end

task :build_yacc_parser do
  assert_dependency_version("Bison", "3.8", "yacc --version")
  `yacc graphql-c_parser/ext/graphql_c_parser_ext/parser.y -o graphql-c_parser/ext/graphql_c_parser_ext/parser.c -Wyacc`
end

task :move_binary do
  # For some reason my local env doesn't respect the `lib_dir` configured above
  `mv graphql-c_parser/lib/*.bundle graphql-c_parser/lib/graphql`
end

desc "Build the C Extension"
task build_ext: [:build_c_lexer, :build_yacc_parser, "compile:graphql_c_parser_ext", :move_binary]
