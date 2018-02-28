require 'spec_helper'

describe Gitlab::Utils::StrongMemoize do
  let(:klass) do
    struct = Struct.new(:value) do
      def method_name
        strong_memoize(:method_name) do
          trace << value
          value
        end
      end

      def trace
        @trace ||= []
      end
    end

    struct.include(described_class)
    struct
  end

  subject(:object) { klass.new(value) }

  shared_examples 'caching the value' do
    it 'only calls the block once' do
      value0 = object.method_name
      value1 = object.method_name

      expect(value0).to eq(value)
      expect(value1).to eq(value)
      expect(object.trace).to contain_exactly(value)
    end

    it 'returns and defines the instance variable for the exact value' do
      returned_value = object.method_name
      memoized_value = object.instance_variable_get(:@method_name)

      expect(returned_value).to eql(value)
      expect(memoized_value).to eql(value)
    end
  end

  describe '#strong_memoize' do
    [nil, false, true, 'value', 0, [0]].each do |value|
      context "with value #{value}" do
        let(:value) { value }

        it_behaves_like 'caching the value'
      end
    end
  end

  describe '#clear_memoization' do
    let(:value) { 'mepmep' }

    it 'removes the instance variable' do
      object.method_name

      object.clear_memoization(:method_name)

      expect(object.instance_variable_defined?(:@method_name)).to be(false)
    end
  end
end
