# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::DefinitionsCollector, feature_category: :database do
  let(:dummy_definition_class) do
    Class.new do
      attr_reader :args

      def initialize(*args)
        @args = args
      end
    end
  end

  let(:mapping) do
    {
      foo: dummy_definition_class
    }
  end

  subject(:collector) { described_class.new(mapping) }

  describe '#collect' do
    it 'adds definition to collection' do
      collected_definitions = collector.collect do
        foo(1, 2, 3)
      end

      expect(collected_definitions.map(&:args)).to eq([[1, 2, 3]])
    end

    it 'raises NoMethodError for unknown definition' do
      expect do
        collector.collect do
          bar(1, 2, 3)
        end
      end.to raise_error(NoMethodError)
    end
  end

  describe "#respond_to?" do
    it 'returns true if mapped definition class exists' do
      expect(collector.respond_to?(:foo)).to be_truthy
    end

    it 'returns false if mapped definition class does not exist' do
      expect(collector.respond_to?(:bar)).to be_falsey
    end
  end
end
