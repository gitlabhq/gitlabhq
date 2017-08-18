require 'spec_helper'

describe Projects::ForksCountService do
  let(:project) { build(:project, id: 42) }
  let(:service) { described_class.new(project) }

  describe '#count' do
    it 'returns the number of forks' do
      allow(service).to receive(:uncached_count).and_return(1)

      expect(service.count).to eq(1)
    end

    it 'caches the forks count', :use_clean_rails_memory_store_caching do
      expect(service).to receive(:uncached_count).once.and_return(1)

      2.times { service.count }
    end
  end

  describe '#refresh_cache', :use_clean_rails_memory_store_caching do
    it 'refreshes the cache' do
      expect(service).to receive(:uncached_count).once.and_return(1)

      service.refresh_cache

      expect(service.count).to eq(1)
    end
  end

  describe '#delete_cache', :use_clean_rails_memory_store_caching do
    it 'removes the cache' do
      expect(service).to receive(:uncached_count).twice.and_return(1)

      service.count
      service.delete_cache
      service.count
    end
  end
end
