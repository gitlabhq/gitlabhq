# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Query::NullContext do
  let(:null_context) { GraphQL::Query::NullContext.instance }
  describe "#[]" do
    it "returns nil" do
      assert_nil(null_context[:foo])
    end
  end

  describe "#fetch" do
    it "returns the default value argument" do
      assert_equal(:default, null_context.fetch(:foo, :default))
    end

    it "returns the block result" do
      assert_equal(:default, null_context.fetch(:foo) { :default })
    end

    it "raises a KeyError when not passed a default value or a block" do
      assert_raises(KeyError) { null_context.fetch(:foo) }
    end
  end

  describe "#key?" do
    it "returns false" do
      assert(!null_context.key?(:foo))
    end
  end

  describe "#dig?" do
    it "returns nil" do
      assert_nil(null_context.dig(:foo, :bar, :baz))
    end
  end
end
