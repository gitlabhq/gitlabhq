# frozen_string_literal: true
require 'fast_spec_helper'

RSpec.describe Gitlab::ClassAttributes do
  let(:klass) do
    Class.new do
      include Gitlab::ClassAttributes

      class << self
        attr_reader :counter_1, :counter_2

        # get_class_attribute and set_class_attribute are protected,
        # hence those methods are for testing purpose
        def get_attribute(name)
          get_class_attribute(name)
        end

        def set_attribute(name, value)
          set_class_attribute(name, value)
        end
      end

      after_set_class_attribute do
        @counter_1 ||= 0
        @counter_1 += 1
      end

      after_set_class_attribute do
        @counter_2 ||= 0
        @counter_2 += 2
      end
    end
  end

  let(:subclass) { Class.new(klass) }

  it "returns values set on the class" do
    klass.set_attribute(:foo, :bar)

    expect(klass.get_attribute(:foo)).to eq(:bar)
  end

  it "returns values set on a superclass" do
    klass.set_attribute(:foo, :bar)

    expect(subclass.get_attribute(:foo)).to eq(:bar)
  end

  it "returns values from the subclass over attributes from a superclass" do
    klass.set_attribute(:foo, :baz)
    subclass.set_attribute(:foo, :bar)

    expect(klass.get_attribute(:foo)).to eq(:baz)
    expect(subclass.get_attribute(:foo)).to eq(:bar)
  end

  it "triggers after hooks after set class values" do
    expect(klass.counter_1).to be(nil)
    expect(klass.counter_2).to be(nil)

    klass.set_attribute(:foo, :bar)
    klass.set_attribute(:foo, :bar)

    expect(klass.counter_1).to eq(2)
    expect(klass.counter_2).to eq(4)
  end
end
