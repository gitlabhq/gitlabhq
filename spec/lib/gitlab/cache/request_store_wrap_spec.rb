require 'spec_helper'

describe Gitlab::Cache::RequestStoreWrap, :request_store do
  let(:klass) do
    Class.new do
      extend Gitlab::Cache::RequestStoreWrap

      attr_accessor :id, :name, :result

      def self.name
        'ExpensiveAlgorithm'
      end

      def initialize(id, name, result)
        self.id = id
        self.name = name
        self.result = result
      end

      request_store_wrap_key do
        [id, name]
      end

      request_store_wrap def compute(arg)
        result << arg
      end

      request_store_wrap def repute(arg)
        result << arg
      end
    end
  end

  let(:algorithm) { klass.new('id', 'name', []) }

  context 'when RequestStore is active' do
    it 'does not compute twice for the same argument' do
      result = algorithm.compute(true)

      expect(result).to eq([true])
      expect(algorithm.compute(true)).to eq(result)
      expect(algorithm.result).to eq(result)
    end

    it 'computes twice for the different argument' do
      algorithm.compute(true)
      result = algorithm.compute(false)

      expect(result).to eq([true, false])
      expect(algorithm.result).to eq(result)
    end

    it 'computes twice for the different keys, id' do
      algorithm.compute(true)
      algorithm.id = 'ad'
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
      expect(algorithm.result).to eq(result)
    end

    it 'computes twice for the different keys, name' do
      algorithm.compute(true)
      algorithm.name = 'same'
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
      expect(algorithm.result).to eq(result)
    end

    it 'computes twice for the different class name' do
      algorithm.compute(true)
      allow(klass).to receive(:name).and_return('CheapAlgo')
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
      expect(algorithm.result).to eq(result)
    end

    it 'computes twice for the different method' do
      algorithm.compute(true)
      result = algorithm.repute(true)

      expect(result).to eq([true, true])
      expect(algorithm.result).to eq(result)
    end

    it 'computes twice if RequestStore starts over' do
      algorithm.compute(true)
      RequestStore.end!
      RequestStore.clear!
      RequestStore.begin!
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
      expect(algorithm.result).to eq(result)
    end
  end

  context 'when RequestStore is inactive' do
    before do
      RequestStore.end!
    end

    it 'computes twice even if everything is the same' do
      algorithm.compute(true)
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
      expect(algorithm.result).to eq(result)
    end
  end
end
