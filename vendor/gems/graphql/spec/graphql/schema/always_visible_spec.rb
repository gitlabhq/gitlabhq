# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::AlwaysVisible do
  class AlwaysVisibleSchema < GraphQL::Schema
    class Query < GraphQL::Schema::Object
      def self.visible?(ctx)
        ctx[:visible_was_called] = true
        false
      end

      field :one, Integer
      def one; 1; end
    end
    query(Query)
    use GraphQL::Schema::AlwaysVisible
  end

  class NotAlwaysVisibleSchema < GraphQL::Schema
    query(AlwaysVisibleSchema::Query)
    use GraphQL::Schema::Warden if ADD_WARDEN
  end

  it "Doesn't call visibility methods" do
    res = NotAlwaysVisibleSchema.execute("{ one }")
    assert res.context[:visible_was_called]
    assert_equal ["Schema is not configured for queries"], res["errors"].map { |err| err["message"] }

    res = AlwaysVisibleSchema.execute("{ one }")
    refute res.context[:visible_was_called]
    assert_equal 1, res["data"]["one"]
  end
end
