# frozen_string_literal: true

require 'spec_helper'

describe Users::KeysCountService, :use_clean_rails_memory_store_caching do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#count' do
    before do
      create(:personal_key, user: user)
    end

    it 'returns the number of SSH keys as an Integer' do
      expect(service.count).to eq(1)
    end

    it 'caches the number of keys in Redis', :request_store do
      service.delete_cache
      control_count = ActiveRecord::QueryRecorder.new { service.count }.count
      service.delete_cache

      expect { 2.times { service.count } }.not_to exceed_query_limit(control_count)
    end
  end

  describe '#refresh_cache' do
    it 'refreshes the Redis cache' do
      Rails.cache.write(service.cache_key, 10)
      service.refresh_cache

      expect(Rails.cache.fetch(service.cache_key, raw: true)).to be_zero
    end
  end

  describe '#delete_cache' do
    it 'removes the cache' do
      service.count
      service.delete_cache

      expect(Rails.cache.fetch(service.cache_key, raw: true)).to be_nil
    end
  end

  describe '#uncached_count' do
    it 'returns the number of SSH keys' do
      expect(service.uncached_count).to be_zero
    end

    it 'does not cache the number of keys' do
      recorder = ActiveRecord::QueryRecorder.new do
        2.times { service.uncached_count }
      end

      expect(recorder.count).to be > 0
    end
  end

  describe '#cache_key' do
    it 'returns the cache key' do
      expect(service.cache_key).to eq("users/key-count-service/#{user.id}")
    end
  end
end
