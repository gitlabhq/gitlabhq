# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Cop::DefaultNullTrue" do
  include RubocopTestHelpers

  it "finds and autocorrects `null: true` field configurations" do
    result = run_rubocop_on("spec/fixtures/cop/null_true.rb")
    assert_equal 3, rubocop_errors(result)

    assert_includes result, <<-RUBY
  field :name, String, null: true
                       ^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
    null: true,
    ^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  field :described, [String, null: true], null: true, description: "Something"
                                          ^^^^^^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/null_true.rb")
  end
end
