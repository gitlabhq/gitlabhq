# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Pagination::Connection do
  describe "was_authorized_by_scope_ites?" do
    it "doesn't raise an error for missing runtime state and it updates it if context is assigned later" do
      context = GraphQL::Query.new(GraphQL::Schema, "{ __typename }").context
      conn = GraphQL::Pagination::Connection.new([], context: context)
      assert_nil conn.was_authorized_by_scope_items?

      conn.context = context
      assert_nil conn.was_authorized_by_scope_items?

      Fiber[:__graphql_runtime_info] = { context.query => OpenStruct.new(was_authorized_by_scope_items: true) }
      conn.context = context
      assert_equal true, conn.was_authorized_by_scope_items?
    ensure
      Fiber[:__graphql_runtime_info] = nil
    end
  end
end
