# frozen_string_literal: true

require 'fast_spec_helper'
require_relative "../../../lib/gitlab/with_feature_category"

RSpec.describe Gitlab::WithFeatureCategory do
  describe ".feature_category_for_action" do
    let(:base_controller) do
      Class.new do
        include ::Gitlab::WithFeatureCategory
      end
    end

    let(:controller) do
      Class.new(base_controller) do
        feature_category :foo, %w(update edit)
        feature_category :bar, %w(index show)
        feature_category :quux, %w(destroy)
      end
    end

    let(:subclass) do
      Class.new(controller) do
        feature_category :baz, %w(subclass_index)
      end
    end

    it "is nil when nothing was defined" do
      expect(base_controller.feature_category_for_action("hello")).to be_nil
    end

    it "returns the expected category", :aggregate_failures do
      expect(controller.feature_category_for_action("update")).to eq(:foo)
      expect(controller.feature_category_for_action("index")).to eq(:bar)
      expect(controller.feature_category_for_action("destroy")).to eq(:quux)
    end

    it "returns the expected category for categories defined in subclasses" do
      expect(subclass.feature_category_for_action("subclass_index")).to eq(:baz)
    end

    it "raises an error when defining for the controller and for individual actions" do
      expect do
        Class.new(base_controller) do
          feature_category :hello
          feature_category :goodbye, [:world]
        end
      end.to raise_error(ArgumentError, "hello is defined for all actions, but other categories are set")
    end

    it "raises an error when multiple calls define the same action" do
      expect do
        Class.new(base_controller) do
          feature_category :hello, [:world]
          feature_category :goodbye, ["world"]
        end
      end.to raise_error(ArgumentError, "Actions have multiple feature categories: world")
    end

    it "does not raise an error when multiple calls define the same action and feature category" do
      expect do
        Class.new(base_controller) do
          feature_category :hello, [:world]
          feature_category :hello, ["world"]
        end
      end.not_to raise_error
    end
  end
end
