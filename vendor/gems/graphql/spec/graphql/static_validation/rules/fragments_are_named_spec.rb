# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentTypesExist do
  include StaticValidationHelpers

  let(:query_string) {"
    fragment on Cheese {
      id
      flavor
    }
  "}

  it "finds non-existent types on fragments" do
    assert_equal(1, errors.length)
    fragment_def_error = {
      "message"=>"Fragment definition has no name",
      "locations"=>[{"line"=>2, "column"=>5}],
      "path"=>["fragment "],
      "extensions"=>{"code"=>"anonymousFragment"}
    }
    assert_includes(errors, fragment_def_error, "on fragment definitions")
  end
end
