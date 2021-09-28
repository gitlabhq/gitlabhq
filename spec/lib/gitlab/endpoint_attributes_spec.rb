# frozen_string_literal: true

require 'fast_spec_helper'
require_relative "../../../lib/gitlab/endpoint_attributes"

RSpec.describe Gitlab::EndpointAttributes do
  let(:base_controller) do
    Class.new do
      include ::Gitlab::EndpointAttributes
    end
  end

  let(:controller) do
    Class.new(base_controller) do
      feature_category :foo, %w(update edit)
      feature_category :bar, %w(index show)
      feature_category :quux, %w(destroy)

      target_duration :fast, %w(do_a)
      target_duration :slow, %w(do_b do_c)
    end
  end

  let(:subclass) do
    Class.new(controller) do
      feature_category :baz, %w(subclass_index)
      target_duration :very_fast, %w(superclass_do_something)
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

  it "falls back to medium when target_duration was not defined", :aggregate_failures do
    expect(base_controller.target_duration_for_action("hello")).to be_a_target_duration(:medium)
    expect(controller.target_duration_for_action("update")).to be_a_target_duration(:medium)
    expect(controller.target_duration_for_action("index")).to be_a_target_duration(:medium)
    expect(controller.target_duration_for_action("destroy")).to be_a_target_duration(:medium)
  end

  it "returns the expected target_duration", :aggregate_failures do
    expect(controller.target_duration_for_action("do_a")).to be_a_target_duration(:fast)
    expect(controller.target_duration_for_action("do_b")).to be_a_target_duration(:slow)
    expect(controller.target_duration_for_action("do_c")).to be_a_target_duration(:slow)
  end

  it "returns feature category for an implied action if not specify actions" do
    klass = Class.new(base_controller) do
      feature_category :foo
    end
    expect(klass.feature_category_for_action("index")).to eq(:foo)
    expect(klass.feature_category_for_action("show")).to eq(:foo)
  end

  it "returns expected duration for an implied action if not specify actions" do
    klass = Class.new(base_controller) do
      feature_category :foo
      target_duration :slow
    end
    expect(klass.target_duration_for_action("index")).to be_a_target_duration(:slow)
    expect(klass.target_duration_for_action("show")).to be_a_target_duration(:slow)
  end

  it "returns the expected category for categories defined in subclasses" do
    expect(subclass.feature_category_for_action("subclass_index")).to eq(:baz)
  end

  it "falls back to superclass's feature category" do
    expect(subclass.feature_category_for_action("update")).to eq(:foo)
  end

  it "returns the expected target_duration for categories defined in subclasses" do
    expect(subclass.target_duration_for_action("superclass_do_something")).to be_a_target_duration(:very_fast)
  end

  it "falls back to superclass's expected duration" do
    expect(subclass.target_duration_for_action("do_a")).to be_a_target_duration(:fast)
  end

  it "raises an error when defining for the controller and for individual actions" do
    expect do
      Class.new(base_controller) do
        feature_category :hello
        feature_category :goodbye, [:world]
      end
    end.to raise_error(ArgumentError, "feature_category are already defined for all actions, but re-defined for world")
  end

  it "raises an error when multiple calls define the same action" do
    expect do
      Class.new(base_controller) do
        feature_category :hello, [:world]
        feature_category :goodbye, ["world"]
      end
    end.to raise_error(ArgumentError, "Attributes re-defined for action world: feature_category")
  end

  it "raises an error when multiple calls define the same action" do
    expect do
      Class.new(base_controller) do
        target_duration :fast, [:world]
        target_duration :slow, ["world"]
      end
    end.to raise_error(ArgumentError, "Attributes re-defined for action world: target_duration")
  end

  it "does not raise an error when multiple calls define the same action and configs" do
    expect do
      Class.new(base_controller) do
        feature_category :hello, [:world]
        feature_category :hello, ["world"]
        target_duration :fast, [:moon]
        target_duration :fast, ["moon"]
      end
    end.not_to raise_error
  end

  it "raises an error if the expected duration is not supported" do
    expect do
      Class.new(base_controller) do
        target_duration :super_slow
      end
    end.to raise_error(ArgumentError, "Target duration not supported: super_slow")
  end
end
