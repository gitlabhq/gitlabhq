require 'spec_helper'

describe BaseCountService, :use_clean_rails_memory_store_caching do
  let(:service) { described_class.new }

  describe '#relation_for_count' do
    it 'raises NotImplementedError' do
      expect { service.relation_for_count }.to raise_error(NotImplementedError)
    end
  end

  describe '#count' do
    it 'returns the number of values' do
      expect(service)
        .to receive(:cache_key)
        .and_return('foo')

      expect(service)
        .to receive(:uncached_count)
        .and_return(5)

      expect(service.count).to eq(5)
    end
  end

  describe '#uncached_count' do
    it 'returns the uncached number of values' do
      expect(service)
        .to receive(:relation_for_count)
        .and_return(double(:relation, count: 5))

      expect(service.uncached_count).to eq(5)
    end
  end

  describe '#refresh_cache' do
    it 'refreshes the cache' do
      allow(service)
        .to receive(:cache_key)
        .and_return('foo')

      allow(service)
        .to receive(:uncached_count)
        .and_return(4)

      service.refresh_cache

      expect(Rails.cache.fetch(service.cache_key, raw: service.raw?)).to eq(4)
    end
  end

  describe '#delete_cache' do
    it 'deletes the cache' do
      allow(service)
        .to receive(:cache_key)
        .and_return('foo')

      allow(service)
        .to receive(:uncached_count)
        .and_return(4)

      service.refresh_cache
      service.delete_cache

      expect(Rails.cache.fetch(service.cache_key, raw: service.raw?)).to be_nil
    end
  end

  describe '#raw?' do
    it 'returns false' do
      expect(service.raw?).to eq(false)
    end
  end

  describe '#cache_key' do
    it 'raises NotImplementedError' do
      expect { service.cache_key }.to raise_error(NotImplementedError)
    end
  end

  describe '#cache_options' do
    it 'returns the default in options' do
      expect(service.cache_options).to eq({ raw: false })
    end
  end
end
