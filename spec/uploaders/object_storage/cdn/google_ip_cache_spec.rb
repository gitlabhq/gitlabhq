# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectStorage::CDN::GoogleIpCache,
  :use_clean_rails_memory_store_caching, :use_clean_rails_redis_caching do
  include StubRequests

  let(:subnets) { [IPAddr.new("34.80.0.0/15"), IPAddr.new("2600:1900:4180::/44")] }
  let(:public_ip) { '18.245.0.42' }

  describe '.update!' do
    it 'caches to both L1 and L2 caches' do
      expect(Gitlab::ProcessMemoryCache.cache_backend.exist?(described_class::GOOGLE_CDN_LIST_KEY)).to be false
      expect(Rails.cache.exist?(described_class::GOOGLE_CDN_LIST_KEY)).to be false

      described_class.update!(subnets)

      expect(Gitlab::ProcessMemoryCache.cache_backend.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to eq(subnets)
      expect(Rails.cache.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to eq(subnets)
    end
  end

  describe '.ready?' do
    it 'returns false' do
      expect(described_class.ready?).to be false
    end

    it 'returns true' do
      described_class.update!(subnets)

      expect(described_class.ready?).to be true
    end
  end

  describe '.google_ip?' do
    using RSpec::Parameterized::TableSyntax

    where(:ip_address, :expected) do
      '34.80.0.1'                               | true
      '18.245.0.42'                             | false
      '2500:1900:4180:0000:0000:0000:0000:0000' | false
      '2600:1900:4180:0000:0000:0000:0000:0000' | true
      '10.10.1.5'                               | false
      'fc00:0000:0000:0000:0000:0000:0000:0000' | false
    end

    before do
      described_class.update!(subnets)
    end

    with_them do
      it { expect(described_class.google_ip?(ip_address)).to eq(expected) }
    end

    it 'uses the L2 cache and updates the L1 cache when L1 is missing' do
      Gitlab::ProcessMemoryCache.cache_backend.delete(described_class::GOOGLE_CDN_LIST_KEY)
      expect(Rails.cache.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to eq(subnets)

      expect(described_class.google_ip?(public_ip)).to be false

      expect(Gitlab::ProcessMemoryCache.cache_backend.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to eq(subnets)
      expect(Rails.cache.fetch(described_class::GOOGLE_CDN_LIST_KEY)).to eq(subnets)
    end

    it 'avoids populating L1 cache if L2 is missing' do
      Gitlab::ProcessMemoryCache.cache_backend.delete(described_class::GOOGLE_CDN_LIST_KEY)
      Rails.cache.delete(described_class::GOOGLE_CDN_LIST_KEY)

      expect(described_class.google_ip?(public_ip)).to be false

      expect(Gitlab::ProcessMemoryCache.cache_backend.exist?(described_class::GOOGLE_CDN_LIST_KEY)).to be false
      expect(Rails.cache.exist?(described_class::GOOGLE_CDN_LIST_KEY)).to be false
    end
  end

  describe '.async_refresh' do
    it 'schedules the worker' do
      expect(::GoogleCloud::FetchGoogleIpListWorker).to receive(:perform_async)

      described_class.async_refresh
    end
  end
end
