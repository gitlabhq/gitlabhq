# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::Autoflow::ValueConverter, feature_category: :deployment_management do
  describe '.to_value' do
    it 'converts a string' do
      expect(described_class.to_value('hello').string_value).to eq('hello')
    end

    it 'converts an integer' do
      expect(described_class.to_value(42).integer_value).to eq(42)
    end

    it 'converts a float' do
      expect(described_class.to_value(1.5).float_value).to eq(1.5)
    end

    it 'converts a boolean' do
      expect(described_class.to_value(true).bool_value).to be(true)
    end

    it 'converts nil to a none value' do
      expect(described_class.to_value(nil).none_value).to eq(:NONE_VALUE)
    end

    it 'converts an array to a list value' do
      expect(described_class.to_value(%w[a b]).list_value.values.map(&:string_value)).to eq(%w[a b])
    end

    it 'converts a hash to a dict value with stringified keys' do
      result = described_class.to_value({ name: 'runner', replicas: 2 })

      pairs = result.dict_value.key_values.to_h { |kv| [kv.key.string_value, kv.val] }
      expect(pairs.keys).to contain_exactly('name', 'replicas')
      expect(pairs['name'].string_value).to eq('runner')
      expect(pairs['replicas'].integer_value).to eq(2)
    end

    it 'converts nested structures recursively' do
      result = described_class.to_value({ 'services' => [{ 'name' => 'runner' }] })

      services = result.dict_value.key_values.first.val.list_value.values
      name = services.first.dict_value.key_values.first
      expect(name.key.string_value).to eq('name')
      expect(name.val.string_value).to eq('runner')
    end

    it 'passes an existing Value through unchanged' do
      value = Gitlab::Agent::Autoflow::Value.new(string_value: 'x')

      expect(described_class.to_value(value)).to be(value)
    end

    it 'raises for an unsupported type' do
      expect { described_class.to_value(Object.new) }
        .to raise_error(ArgumentError, /unsupported AutoFlow value type/)
    end
  end

  describe '.named_values' do
    it 'builds NamedValue entries keyed by name' do
      result = described_class.named_values('environment' => { 'id' => '42' })

      expect(result.size).to eq(1)
      expect(result.first.name).to eq('environment')
      expect(result.first.value.dict_value.key_values.first.key.string_value).to eq('id')
    end
  end

  describe '.values' do
    it 'builds an array of Values' do
      expect(described_class.values(['a', 1]).map(&:kind)).to eq(%i[string_value integer_value])
    end
  end
end
