# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Cop::RootTypesInBlock" do
  include RubocopTestHelpers

  it "finds and autocorrects field corrections with inline types" do
    result = run_rubocop_on("spec/fixtures/cop/root_types.rb")
    assert_equal 3, rubocop_errors(result)

    assert_includes result, <<-RUBY
  query Types::Query
  ^^^^^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  mutation Types::Mutation
  ^^^^^^^^^^^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  subscription Types::Subscription
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/root_types.rb")
  end
end
