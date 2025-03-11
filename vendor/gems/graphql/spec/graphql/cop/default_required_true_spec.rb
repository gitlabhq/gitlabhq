# frozen_string_literal: true
require 'spec_helper'

describe "GraphQL::Cop::DefaultRequiredTrue" do
  include RubocopTestHelpers

  it "finds and autocorrects `required: true` argument configurations" do
    result = run_rubocop_on("spec/fixtures/cop/required_true.rb")
    assert_equal 4, rubocop_errors(result)

    assert_includes result, <<-RUBY
    argument :id_1, ID, required: true
                        ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
      required: true,
      ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
    argument :id_3, ID, other_config: { something: false, required: true }, required: true, description: \"Something\"
                                                                            ^^^^^^^^^^^^^^
    RUBY

    assert_includes result, <<-RUBY
    f.argument(:id_1, ID, required: true)
                          ^^^^^^^^^^^^^^
    RUBY

    assert_rubocop_autocorrects_all("spec/fixtures/cop/required_true.rb")
  end
end
