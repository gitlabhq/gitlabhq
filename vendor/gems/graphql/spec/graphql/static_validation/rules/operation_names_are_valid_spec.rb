# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::OperationNamesAreValid do
  include StaticValidationHelpers

  describe "when there are multiple operations" do
    let(:query_string) { <<-GRAPHQL
    query getCheese {
      cheese(id: 1) { flavor }
    }

    {
      cheese(id: 2) { flavor }
    }

    {
      cheese(id: 3) { flavor }
    }
    GRAPHQL
    }

    it "must have operation names" do
      assert_equal 1, errors.length
      requires_name_error = {
        "message"=>"Operation name is required when multiple operations are present",
        "locations"=>[{"line"=>5, "column"=>5}, {"line"=>9, "column"=>5}],
        "path"=>[],
        "extensions"=>{"code"=>"uniquelyNamedOperations"}
      }
      assert_includes(errors, requires_name_error)
    end
  end

  describe "when there are only unnamed operations" do
    let(:query_string) { <<-GRAPHQL
    {
      cheese(id: 2) { flavor }
    }

    {
      cheese(id: 3) { flavor }
    }
    GRAPHQL
    }

    it "requires names" do
      assert_equal 1, errors.length
      requires_name_error = {
        "message"=>"Operation name is required when multiple operations are present",
        "locations"=>[{"line"=>1, "column"=>5}, {"line"=>5, "column"=>5}],
        "path"=>[],
        "extensions"=>{"code"=>"uniquelyNamedOperations"}
      }
      assert_includes(errors, requires_name_error)
    end
  end

  describe "when multiple operations have names" do
    let(:query_string) { <<-GRAPHQL
    query getCheese {
      cheese(id: 1) { flavor }
    }

    query getCheese {
      cheese(id: 2) { flavor }
    }
    GRAPHQL
    }

    it "must be unique" do
      assert_equal 1, errors.length
      name_uniqueness_error = {
        "message"=>'Operation name "getCheese" must be unique',
        "locations"=>[{"line"=>1, "column"=>5}, {"line"=>5, "column"=>5}],
        "path"=>[],
        "extensions"=>{"code"=>"uniquelyNamedOperations", "operationName"=>"getCheese"}
      }
      assert_includes(errors, name_uniqueness_error)
    end
  end

  describe "with error limiting" do
    let(:query_string) { <<-GRAPHQL
    query getCheese {
      cheese(id: 1) { flavor }
    }
    query getCheese {
      cheese(id: 2) { flavor }
    }
    query getCheeses{
      searchDairy(product: [{ source: COW }]) {
        __typename
      }
    }
    query getCheeses{
      searchDairy(product: [{ source: COW }]) {
        __typename
      }
    }
    GRAPHQL
    }
    describe("disabled") do
      let(:args) {
        { max_errors: nil }
      }

      it "does not limit the number of errors" do
        assert_equal(error_messages.length, 2)
        assert_equal(error_messages, [
          "Operation name \"getCheese\" must be unique",
          "Operation name \"getCheeses\" must be unique"
        ])
      end
    end

    describe("enabled") do
      let(:args) {
        { max_errors: 1 }
      }

      it "does limit the number of errors" do
        assert_equal(error_messages.length, 1)
        assert_equal(error_messages, [
          "Operation name \"getCheese\" must be unique",
        ])
      end
    end
  end
end
