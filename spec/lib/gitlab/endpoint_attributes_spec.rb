# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EndpointAttributes, feature_category: :api do
  let(:base_controller) do
    Class.new do
      include ::Gitlab::EndpointAttributes
    end
  end

  let(:controller) do
    Class.new(base_controller) do
      feature_category :foo, %w[update edit]
      feature_category :bar, %w[index show]
      feature_category :quux, %w[destroy]

      urgency :high, %w[do_a]
      urgency :low, %w[do_b do_c]
    end
  end

  let(:subclass) do
    Class.new(controller) do
      feature_category :baz, %w[subclass_index]
      urgency :high, %w[superclass_do_something]
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

  it "falls back to default when urgency was not defined", :aggregate_failures do
    expect(base_controller.urgency_for_action("hello")).to be_request_urgency(:default)
    expect(controller.urgency_for_action("update")).to be_request_urgency(:default)
    expect(controller.urgency_for_action("index")).to be_request_urgency(:default)
    expect(controller.urgency_for_action("destroy")).to be_request_urgency(:default)
  end

  it "returns the expected urgency", :aggregate_failures do
    expect(controller.urgency_for_action("do_a")).to be_request_urgency(:high)
    expect(controller.urgency_for_action("do_b")).to be_request_urgency(:low)
    expect(controller.urgency_for_action("do_c")).to be_request_urgency(:low)
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
      urgency :low
    end
    expect(klass.urgency_for_action("index")).to be_request_urgency(:low)
    expect(klass.urgency_for_action("show")).to be_request_urgency(:low)
  end

  it "returns the expected category for categories defined in subclasses" do
    expect(subclass.feature_category_for_action("subclass_index")).to eq(:baz)
  end

  it "falls back to superclass's feature category" do
    expect(subclass.feature_category_for_action("update")).to eq(:foo)
  end

  it "returns the expected urgency for categories defined in subclasses" do
    expect(subclass.urgency_for_action("superclass_do_something")).to be_request_urgency(:high)
  end

  it "falls back to superclass's expected duration" do
    expect(subclass.urgency_for_action("do_a")).to be_request_urgency(:high)
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
        urgency :high, [:world]
        urgency :low, ["world"]
      end
    end.to raise_error(ArgumentError, "Attributes re-defined for action world: urgency")
  end

  it "does not raise an error when multiple calls define the same action and configs" do
    expect do
      Class.new(base_controller) do
        feature_category :hello, [:world]
        feature_category :hello, ["world"]
        urgency :medium, [:moon]
        urgency :medium, ["moon"]
      end
    end.not_to raise_error
  end

  it "raises an error if the expected duration is not supported" do
    expect do
      Class.new(base_controller) do
        urgency :super_slow
      end
    end.to raise_error(ArgumentError, "Urgency not supported: super_slow")
  end
end
