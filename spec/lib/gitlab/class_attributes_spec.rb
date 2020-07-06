# frozen_string_literal: true
require 'fast_spec_helper'

RSpec.describe Gitlab::ClassAttributes do
  let(:klass) do
    Class.new do
      include Gitlab::ClassAttributes

      def self.get_attribute(name)
        get_class_attribute(name)
      end

      def self.set_attribute(name, value)
        class_attributes[name] = value
      end
    end
  end

  let(:subclass) { Class.new(klass) }

  describe ".get_class_attribute" do
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

      expect(subclass.get_attribute(:foo)).to eq(:bar)
    end
  end
end
