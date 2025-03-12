# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Member::HasArguments do
  class DefaultArgumentAuthSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      field :add, Int do
        argument :left, Int
        argument :right, Int, required: false, default_value: 1 do
          def authorized?(_object, _arg_value, context)
            !!context[:is_authorized]
          end
        end
      end

      def add(left:, right:)
        left + right
      end
    end

    query(Query)
  end

  it "doesn't require authorization when arguments with default values aren't present in the query" do
    assert_equal 5, DefaultArgumentAuthSchema.execute("{ add(left: 3, right: 2) }", context: { is_authorized: true })["data"].fetch("add")
    assert_nil DefaultArgumentAuthSchema.execute("{ add(left: 3, right: 2) }", context: { is_authorized: false })["data"].fetch("add")
    assert_equal 4, DefaultArgumentAuthSchema.execute("{ add(left: 3) }", context: { is_authorized: false })["data"].fetch("add")
  end
end
