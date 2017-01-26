require 'spec_helper'

describe Prependable do
  subject { FooObject }

  context 'class methods' do
    it "has a method" do
      expect(subject).to respond_to(:class_value)
    end

    it 'can execute a method' do
      expect(subject.class_value).to eq(20)
    end
  end

  context 'instance methods' do
    it "has a method" do
      expect(subject.new).to respond_to(:value)
    end

    it 'chains a method execution' do
      expect(subject.new.value).to eq(100)
    end
  end

  module Foo
    extend ActiveSupport::Concern

    prepended do
      def self.class_value
        20
      end
    end

    def value
      super * 10
    end
  end

  class FooObject
    prepend Foo

    def value
      10
    end
  end
end
