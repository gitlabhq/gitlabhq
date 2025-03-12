# frozen_string_literal: true
require "spec_helper"
require "open3"

describe GraphQL do
  it "loads without warnings" do
    stderr_and_stdout, _status = Open3.capture2e(%|ruby -Ilib -e "require 'bundler/inline'; gemfile(true, quiet: true) { source('https://rubygems.org'); gem('fiber-storage'); gem('graphql', path: './') }; GraphQL.eager_load!"|)
    puts stderr_and_stdout
    assert_equal "", stderr_and_stdout
  end
end
