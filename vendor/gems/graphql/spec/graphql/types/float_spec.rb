# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Float do
  let(:enum) { GraphQL::Language::Nodes::Enum.new(name: 'MILK') }

  describe "coerce_input" do
    it "accepts ints and floats" do
      assert_equal 1.0, GraphQL::Types::Float.coerce_isolated_input(1)
      assert_equal 6.1, GraphQL::Types::Float.coerce_isolated_input(6.1)
    end

    it "rejects other types" do
      assert_nil GraphQL::Types::Float.coerce_isolated_input("55")
      assert_nil GraphQL::Types::Float.coerce_isolated_input(true)
      assert_nil GraphQL::Types::Float.coerce_isolated_input(enum)
    end
  end
end
