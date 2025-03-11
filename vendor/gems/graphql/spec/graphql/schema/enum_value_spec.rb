# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::EnumValue do
  describe "#path" do
    it "Has the owner name too" do
      enum = Class.new(GraphQL::Schema::Enum) do
        graphql_name "Abc"
        value(:XYZ)
      end

      assert_equal "Abc.XYZ", enum.values["XYZ"].path
    end
  end

  it "can accept a proc as a value" do
    enum = Class.new(GraphQL::Schema::Enum) do
      graphql_name "SortBy"
      value 'BY_NAME', value: ->(scope, direction: :asc) {
        scope.order(name: direction)
      }
      value 'BY_EMAIL', value: ->(scope, direction: :asc) {
        scope.order(email: direction)
      }
    end

    assert_instance_of Proc, enum.values["BY_NAME"].value
  end

  describe "#deprecation_reason" do
    it "can be written and read" do
      enum_value = GraphQL::Schema::EnumValue.new(:x, owner: nil)
      assert_nil enum_value.deprecation_reason
      enum_value.deprecation_reason = "No good!"
      assert_equal "No good!", enum_value.deprecation_reason
    end
  end
end
