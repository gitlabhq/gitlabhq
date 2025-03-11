# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Cop::FieldTypeInBlock" do
  include RubocopTestHelpers

  it "finds and autocorrects field corrections with inline types" do
    result = run_rubocop_on("spec/fixtures/cop/field_type.rb")
    assert_equal 3, rubocop_errors(result)

    assert_includes result, <<-RUBY
  field :current_account, Types::Account, null: false, description: "The account of the current viewer"
                          ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  field :find_account, Types::Account do
                       ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
  field(:all_accounts, [Types::Account, null: false]) {
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/field_type.rb")
  end

  it "works on small classes" do
    result = run_rubocop_on("spec/fixtures/cop/small_field_type.rb")
    assert_equal 1, rubocop_errors(result)
  end

  it "works with array types" do
    result = run_rubocop_on("spec/fixtures/cop/field_type_array.rb")
    assert_equal 1, rubocop_errors(result)

    assert_includes result, <<-RUBY
  field :bar, [Thing], null: false do
              ^^^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/field_type_array.rb")
  end

  it "Works with interfaces" do
    result = run_rubocop_on("spec/fixtures/cop/field_type_interface.rb")
    assert_equal 1, rubocop_errors(result)

    assert_includes result, <<-RUBY
  field :thing, Thing
                ^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/field_type_interface.rb")
  end
end
