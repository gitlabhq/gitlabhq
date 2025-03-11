# frozen_string_literal: true
require "spec_helper"

describe GraphQL::TypeKinds::TypeKind do
  describe ".leaf?" do
    it "is true for enums and scalars, but false for others" do
      assert GraphQL::Schema::Scalar.kind.leaf?
      assert GraphQL::Schema::Enum.kind.leaf?
      refute GraphQL::Schema::Object.kind.leaf?
      refute GraphQL::Schema::Interface.kind.leaf?
      refute GraphQL::Schema::Union.kind.leaf?
      refute GraphQL::Schema::InputObject.kind.leaf?
    end
  end
end
