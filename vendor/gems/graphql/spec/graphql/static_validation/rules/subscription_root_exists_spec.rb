# frozen_string_literal: true
require "spec_helper"

describe GraphQL::StaticValidation::SubscriptionRootExists do
  include StaticValidationHelpers

  let(:query_string) {%|
    subscription {
      test
    }
  |}

  let(:schema) {
    Class.new(GraphQL::Schema) do
      query_root = Class.new(GraphQL::Schema::Object) do
        graphql_name "Query"
      end

      query query_root
    end
  }

  it "errors when a subscription is performed on a schema without a subscription root" do
    assert_equal(1, errors.length)
    missing_subscription_root_error = {
      "message"=>"Schema is not configured for subscriptions",
      "locations"=>[{"line"=>2, "column"=>5}],
      "path"=>["subscription"],
      "extensions"=>{"code"=>"missingSubscriptionConfiguration"}
    }
    assert_includes(errors, missing_subscription_root_error)
  end
end
