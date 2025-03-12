# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::FragmentNamesAreUnique do
  include StaticValidationHelpers

  let(:query_string) {"
    query {
      cheese(id: 1) {
        ... frag1
      }
    }

    fragment frag1 on Cheese { id }
    fragment frag1 on Cheese { id }
  "}

  it "requires unique fragment names" do
    assert_equal(1, errors.length)
    fragment_def_error = {
      "message"=>"Fragment name \"frag1\" must be unique",
      "locations"=>[{"line"=>8, "column"=>5}, {"line"=>9, "column"=>5}],
      "path"=>[],
      "extensions"=>{"code"=>"fragmentNotUnique", "fragmentName"=>"frag1"}
    }
    assert_includes(errors, fragment_def_error)
  end

  describe "when used in a spread" do
    let(:query_string) {"
      query {
        cheese(id: 1) {
          ... frag1
        }
      }

      fragment frag1 on Cheese { ...frag2 }
      fragment frag1 on Cheese { ...frag2 }
      fragment frag2 on Cheese { id }
    "}

    it "finds the error" do
      assert_equal(1, errors.length)
      fragment_def_error = {
        "message"=>"Fragment name \"frag1\" must be unique",
        "locations"=>[{"line"=>8, "column"=>7}, {"line"=>9, "column"=>7}],
        "path"=>[],
        "extensions"=>{"code"=>"fragmentNotUnique", "fragmentName"=>"frag1"}
      }
      assert_includes(errors, fragment_def_error)
    end
  end

  describe "when used at second level" do
    let(:query_string) {"
      query {
        cheese(id: 1) {
          ... frag1
        }
      }

      fragment frag1 on Cheese { ...frag2 }
      fragment frag2 on Cheese { id }
      fragment frag2 on Cheese { id }
    "}

    it "finds the error" do
      assert_equal(1, errors.length)
      fragment_def_error = {
        "message"=>"Fragment name \"frag2\" must be unique",
        "locations"=>[{"line"=>9, "column"=>7}, {"line"=>10, "column"=>7}],
        "path"=>[],
        "extensions"=>{"code"=>"fragmentNotUnique", "fragmentName"=>"frag2"}
      }
      assert_includes(errors, fragment_def_error)
    end
  end
end
