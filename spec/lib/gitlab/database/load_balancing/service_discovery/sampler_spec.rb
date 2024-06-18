# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Database::LoadBalancing::ServiceDiscovery::Sampler do
  let(:sampler) { described_class.new(max_replica_pools: max_replica_pools, seed: 100) }
  let(:max_replica_pools) { 3 }
  let(:address_class) { ::Gitlab::Database::LoadBalancing::ServiceDiscovery::Address }
  let(:addresses) do
    [
      address_class.new("127.0.0.1", 6432),
      address_class.new("127.0.0.1", 6433),
      address_class.new("127.0.0.1", 6434),
      address_class.new("127.0.0.1", 6435),
      address_class.new("127.0.0.2", 6432),
      address_class.new("127.0.0.2", 6433),
      address_class.new("127.0.0.2", 6434),
      address_class.new("127.0.0.2", 6435)
    ]
  end

  describe '#sample' do
    it 'samples max_replica_pools addresses' do
      expect(sampler.sample(addresses).count).to eq(max_replica_pools)
    end

    it 'samples random ports across all hosts' do
      expect(sampler.sample(addresses)).to eq([
        address_class.new("127.0.0.1", 6432),
                                                address_class.new("127.0.0.2", 6435),
                                                address_class.new("127.0.0.1", 6435)
      ])
    end

    it 'returns the same answer for the same input when called multiple times' do
      result = sampler.sample(addresses)
      expect(sampler.sample(addresses)).to eq(result)
      expect(sampler.sample(addresses)).to eq(result)
    end

    it 'gives a consistent answer regardless of input ordering' do
      expect(sampler.sample(addresses.reverse)).to eq(sampler.sample(addresses))
    end

    it 'samples fairly across all hosts' do
      # Choose a bunch of different seeds to prove that it always chooses 2
      # different ports from each host when selecting 4
      (1..10).each do |seed|
        sampler = described_class.new(max_replica_pools: 4, seed: seed)

        result = sampler.sample(addresses)

        expect(result.count { |r| r.hostname == "127.0.0.1" }).to eq(2)
        expect(result.count { |r| r.hostname == "127.0.0.2" }).to eq(2)
      end
    end

    context 'when input is an empty array' do
      it 'returns an empty array' do
        expect(sampler.sample([])).to eq([])
      end
    end

    context 'when there are less replicas than max_replica_pools' do
      let(:max_replica_pools) { 100 }

      it 'returns the same addresses' do
        expect(sampler.sample(addresses)).to eq(addresses)
      end
    end

    context 'when max_replica_pools is nil' do
      let(:max_replica_pools) { nil }

      it 'returns the same addresses' do
        expect(sampler.sample(addresses)).to eq(addresses)
      end
    end
  end
end
