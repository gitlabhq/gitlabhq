# frozen_string_literal: true
require "spec_helper"

describe "GraphQL::InvalidNullError" do
  it "can be inspected" do
    assert_equal "GraphQL::InvalidNullError", GraphQL::InvalidNullError.inspect
  end
end
