# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::DefinitionsCollector, feature_category: :database do
  let(:dummy_definition_class) do
    Class.new do
      attr_reader :args, :kwargs

      def initialize(*args, **kwargs)
        @args = args
        @kwargs = kwargs
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

      expect(collected_definitions.map(&:args)).to match_array([[1, 2, 3]])
    end

    it 'raises NoMethodError for unknown definition' do
      expect do
        collector.collect do
          bar(1, 2, 3)
        end
      end.to raise_error(NoMethodError)
    end
  end

  describe '#collect with transients' do
    let(:expression) { -> { 'resolved_expression' } }
    let(:transients) { { my_transient: expression } }

    subject(:collector) { described_class.new(mapping, transients: transients) }

    it 'returns transient lambda via transient() helper' do
      collected_definitions = collector.collect do
        foo(:name, :integer, transient(:my_transient))
      end

      definition = collected_definitions.first
      expect(definition.args).to eq([:name, :integer, expression])
    end

    it 'returns transient lambda in keyword arguments' do
      collected_definitions = collector.collect do
        foo(:name, condition: transient(:my_transient))
      end

      definition = collected_definitions.first
      expect(definition.kwargs).to eq({ condition: expression })
    end

    it 'raises KeyError for unknown transient name' do
      expect do
        collector.collect do
          foo(:name, :integer, transient(:unknown))
        end
      end.to raise_error(KeyError)
    end
  end

  describe 'gid_formatter' do
    let(:formatter) do
      collector.collect { foo(formatter: gid_formatter) }.first.kwargs[:formatter]
    end

    let(:mapping) do
      { foo: dummy_definition_class }
    end

    it 'extracts model_id from a GlobalID string' do
      expect(formatter.call("gid://gitlab/User/42")).to eq([42])
    end

    it 'extracts model_ids from multiple GlobalID strings' do
      expect(formatter.call(%w[gid://gitlab/User/1 gid://gitlab/User/2])).to eq([1, 2])
    end

    it 'extracts model_id from a GlobalID object' do
      gid = GlobalID.parse("gid://gitlab/User/7")
      expect(formatter.call(gid)).to eq([7])
    end

    it 'extracts model_ids from multiple GlobalID objects' do
      gids = [GlobalID.parse("gid://gitlab/User/1"), GlobalID.parse("gid://gitlab/User/2")]
      expect(formatter.call(gids)).to eq([1, 2])
    end

    it 'falls back to the original value when the input is not a valid GlobalID' do
      expect(formatter.call("not-a-gid")).to eq(["not-a-gid"])
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
