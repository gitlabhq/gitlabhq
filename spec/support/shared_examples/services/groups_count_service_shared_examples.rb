# frozen_string_literal: true

# The calling spec should use `:use_clean_rails_memory_store_caching`
# when including this shared example. E.g.:
#
#   describe MyCountService, :use_clean_rails_memory_store_caching do
#     it_behaves_like 'a counter caching service with threshold'
#   end
RSpec.shared_examples 'a counter caching service with threshold' do
  let(:cache_key) { subject.cache_key }
  let(:under_threshold) { described_class::CACHED_COUNT_THRESHOLD - 1 }
  let(:over_threshold) { described_class::CACHED_COUNT_THRESHOLD + 1 }

  context 'when cache is empty' do
    before do
      Rails.cache.delete(cache_key)
    end

    it 'refreshes cache if value over threshold' do
      allow(subject).to receive(:uncached_count).and_return(over_threshold)

      expect(subject.count).to eq(over_threshold)
      expect(Rails.cache.read(cache_key)).to eq(over_threshold)
    end

    it 'does not refresh cache if value under threshold' do
      allow(subject).to receive(:uncached_count).and_return(under_threshold)

      expect(subject.count).to eq(under_threshold)
      expect(Rails.cache.read(cache_key)).to be_nil
    end
  end

  context 'when cached count is under the threshold value' do
    before do
      Rails.cache.write(cache_key, under_threshold)
    end

    it 'does not refresh cache' do
      expect(Rails.cache).not_to receive(:write)
      expect(subject.count).to eq(under_threshold)
    end
  end

  context 'when cached count is over the threshold value' do
    before do
      Rails.cache.write(cache_key, over_threshold)
    end

    it 'does not refresh cache' do
      expect(Rails.cache).not_to receive(:write)
      expect(subject.count).to eq(over_threshold)
    end
  end
end
