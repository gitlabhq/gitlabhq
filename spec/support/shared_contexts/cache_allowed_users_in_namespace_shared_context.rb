# frozen_string_literal: true

RSpec.shared_examples 'allowed user IDs are cached' do
  it 'caches the allowed user IDs in cache', :use_clean_rails_memory_store_caching do
    expect do
      expect(described_class.l1_cache_backend).to receive(:fetch).and_call_original
      expect(described_class.l2_cache_backend).not_to receive(:fetch)
      expect(subject).to be_truthy
    end.not_to exceed_query_limit(0)
  end

  it 'caches the allowed user IDs in L1 cache for 1 minute', :use_clean_rails_memory_store_caching do
    travel_to 2.minutes.from_now do
      expect do
        expect(described_class.l1_cache_backend).to receive(:fetch).and_call_original
        expect(described_class.l2_cache_backend).to receive(:fetch).and_call_original
        expect(subject).to be_truthy
      end.not_to exceed_query_limit(0)
    end
  end

  it 'caches the allowed user IDs in L2 cache for 5 minutes', :use_clean_rails_memory_store_caching do
    travel_to 6.minutes.from_now do
      expect do
        expect(described_class.l1_cache_backend).to receive(:fetch).and_call_original
        expect(described_class.l2_cache_backend).to receive(:fetch).and_call_original
        expect(subject).to be_truthy
      end.not_to exceed_query_limit(3)
    end
  end
end
