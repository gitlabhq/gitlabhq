# frozen_string_literal: true

# The calling spec should use `:use_clean_rails_memory_store_caching`
# when including this shared example. E.g.:
#
#   describe MyCountService, :use_clean_rails_memory_store_caching do
#     it_behaves_like 'a counter caching service'
#   end
RSpec.shared_examples 'a counter caching service' do
  describe '#count' do
    it 'caches the count', :request_store do
      subject.delete_cache
      control = ActiveRecord::QueryRecorder.new { subject.count }
      subject.delete_cache

      expect { 2.times { subject.count } }.not_to exceed_query_limit(control)
    end
  end

  describe '#refresh_cache' do
    it 'refreshes the cache' do
      original_count = subject.count
      Rails.cache.write(subject.cache_key, original_count + 1, raw: subject.raw?)

      subject.refresh_cache

      expect(fetch_cache || 0).to eq(original_count)
    end
  end

  describe '#delete_cache' do
    it 'removes the cache' do
      subject.count
      subject.delete_cache

      expect(fetch_cache).to be_nil
    end
  end

  describe '#uncached_count' do
    it 'does not cache the count' do
      subject.delete_cache
      subject.uncached_count

      expect(fetch_cache).to be_nil
    end
  end

  private

  def fetch_cache
    Rails.cache.read(subject.cache_key, raw: subject.raw?)
  end
end
