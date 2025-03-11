# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Types::Int do
  describe "coerce_input" do
    it "accepts ints within the bounds" do
      assert_equal(-(2**31), GraphQL::Types::Int.coerce_isolated_input(-(2**31)))
      assert_equal 1, GraphQL::Types::Int.coerce_isolated_input(1)
      assert_equal (2**31)-1, GraphQL::Types::Int.coerce_isolated_input((2**31)-1)
    end

    it "rejects other types and ints outside the bounds" do
      assert_nil GraphQL::Types::Int.coerce_isolated_input("55")
      assert_nil GraphQL::Types::Int.coerce_isolated_input(true)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(6.1)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(2**31)
      assert_nil GraphQL::Types::Int.coerce_isolated_input(-(2**31 + 1))
    end

    describe "handling boundaries" do
      let(:context) { GraphQL::Query.new(Dummy::Schema, "{ __typename }").context }

      it "accepts result values in bounds" do
        assert_equal 0, GraphQL::Types::Int.coerce_result(0, context)
        assert_equal (2**31) - 1, GraphQL::Types::Int.coerce_result((2**31) - 1, context)
        assert_equal(-(2**31), GraphQL::Types::Int.coerce_result(-(2**31), context))
      end

      it "replaces values, if configured to do so" do
        assert_equal Dummy::Schema::MAGIC_INT_COERCE_VALUE, GraphQL::Types::Int.coerce_result(99**99, context)
      end

      it "raises on values out of bounds" do
        err_ctx = GraphQL::Query.new(Dummy::Schema, "{ __typename }").context
        assert_raises(GraphQL::IntegerEncodingError) { GraphQL::Types::Int.coerce_result(2**31, err_ctx) }
        err = assert_raises(GraphQL::IntegerEncodingError) { GraphQL::Types::Int.coerce_result(-(2**31 + 1), err_ctx) }
        assert_equal "Integer out of bounds: -2147483649. Consider using ID or GraphQL::Types::BigInt instead.", err.message

        err = assert_raises GraphQL::IntegerEncodingError do
          Dummy::Schema.execute("{ hugeInteger }")
        end
        expected_err = "Integer out of bounds: 2147483648 @ hugeInteger (Query.hugeInteger). Consider using ID or GraphQL::Types::BigInt instead."
        assert_equal expected_err, err.message
      end
    end
  end
end
