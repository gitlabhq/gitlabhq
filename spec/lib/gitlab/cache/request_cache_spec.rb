# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::RequestCache do
  let(:klass) do
    Class.new do
      extend Gitlab::Cache::RequestCache

      attr_accessor :id, :name, :result, :extra

      def self.name
        'ExpensiveAlgorithm'
      end

      def initialize(id, name, result, extra = nil)
        self.id = id
        self.name = name
        self.result = result
        self.extra = nil
      end

      request_cache def compute(arg)
        result << arg
      end

      request_cache def repute(arg)
        result << arg
      end

      def dispute(arg)
        result << arg
      end
      request_cache(:dispute) { extra }
    end
  end

  let(:algorithm) { klass.new('id', 'name', []) }

  shared_examples 'cache for the same instance' do
    it 'does not compute twice for the same argument' do
      algorithm.compute(true)
      result = algorithm.compute(true)

      expect(result).to eq([true])
    end

    it 'computes twice for the different argument' do
      algorithm.compute(true)
      result = algorithm.compute(false)

      expect(result).to eq([true, false])
    end

    it 'computes twice for the different class name' do
      algorithm.compute(true)
      allow(klass).to receive(:name).and_return('CheapAlgo')
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
    end

    it 'computes twice for the different method' do
      algorithm.compute(true)
      result = algorithm.repute(true)

      expect(result).to eq([true, true])
    end

    context 'when request_cache_key is provided' do
      before do
        klass.request_cache_key do
          [id, name]
        end
      end

      it 'computes twice for the different keys, id' do
        algorithm.compute(true)
        algorithm.id = 'ad'
        result = algorithm.compute(true)

        expect(result).to eq([true, true])
      end

      it 'computes twice for the different keys, name' do
        algorithm.compute(true)
        algorithm.name = 'same'
        result = algorithm.compute(true)

        expect(result).to eq([true, true])
      end

      it 'uses extra method cache key if provided' do
        algorithm.dispute(true) # miss
        algorithm.extra = true
        algorithm.dispute(true) # miss
        result = algorithm.dispute(true) # hit

        expect(result).to eq([true, true])
      end
    end
  end

  context 'when RequestStore is active', :request_store do
    it_behaves_like 'cache for the same instance'

    it 'computes once for different instances when keys are the same' do
      algorithm.compute(true)
      result = klass.new('id', 'name', algorithm.result).compute(true)

      expect(result).to eq([true])
    end

    it 'computes twice if RequestStore starts over' do
      algorithm.compute(true)
      RequestStore.end!
      RequestStore.clear!
      RequestStore.begin!
      result = algorithm.compute(true)

      expect(result).to eq([true, true])
    end
  end

  context 'when RequestStore is inactive' do
    it_behaves_like 'cache for the same instance'

    it 'computes twice for different instances even if keys are the same' do
      algorithm.compute(true)
      result = klass.new('id', 'name', algorithm.result).compute(true)

      expect(result).to eq([true, true])
    end
  end
end
