require 'spec_helper'

describe Projects::CountService do
  let(:project) { build(:project, id: 1) }
  let(:service) { described_class.new(project) }

  describe '.query' do
    it 'raises NotImplementedError' do
      expect { described_class.query(project.id) }.to raise_error(NotImplementedError)
    end
  end

  describe '#relation_for_count' do
    it 'calls the class method query with the project id' do
      expect(described_class).to receive(:query).with(project.id)

      service.relation_for_count
    end
  end

  describe '#count' do
    before do
      allow(service).to receive(:cache_key_name).and_return('count_service')
    end

    it 'returns the number of rows' do
      allow(service).to receive(:uncached_count).and_return(1)

      expect(service.count).to eq(1)
    end

    it 'caches the number of rows', :use_clean_rails_memory_store_caching do
      expect(service).to receive(:uncached_count).once.and_return(1)

      2.times do
        expect(service.count).to eq(1)
      end
    end
  end

  describe '#refresh_cache', :use_clean_rails_memory_store_caching do
    before do
      allow(service).to receive(:cache_key_name).and_return('count_service')
    end

    it 'refreshes the cache' do
      expect(service).to receive(:uncached_count).once.and_return(1)

      service.refresh_cache

      expect(service.count).to eq(1)
    end
  end

  describe '#delete_cache', :use_clean_rails_memory_store_caching do
    before do
      allow(service).to receive(:cache_key_name).and_return('count_service')
    end

    it 'removes the cache' do
      expect(service).to receive(:uncached_count).twice.and_return(1)

      service.count
      service.delete_cache
      service.count
    end
  end

  describe '#cache_key_name' do
    it 'raises NotImplementedError' do
      expect { service.cache_key_name }.to raise_error(NotImplementedError)
    end
  end

  describe '#cache_key' do
    it 'returns the cache key as an Array' do
      allow(service).to receive(:cache_key_name).and_return('foo')
      expect(service.cache_key).to eq(['projects', 'count_service', described_class::VERSION, 1, 'foo'])
    end
  end
end
