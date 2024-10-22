# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Cache, feature_category: :global_search do
  let_it_be(:resource) { create(:user) }
  let(:action) { 'test' }
  let(:cache_key) { "search_user_#{resource.id}_#{action}" }

  describe '.lookup' do
    it 'uses Rails.cache to fetch the value' do
      expect(Rails.cache).to receive(:fetch)
        .with(cache_key, expires_in: described_class::DEFAULT_EXPIRES_IN)
        .and_call_original

      described_class.lookup(resource: resource, action: action) { 'cached_value' }
    end

    context 'when caching is disabled' do
      it 'does not use the cache' do
        expect(Rails.cache).not_to receive(:fetch)
        result = described_class.lookup(resource: resource, action: action, enabled: false) { 'uncached_value' }
        expect(result).to eq('uncached_value')
      end
    end

    context 'with a custom cache key' do
      let(:custom_cache_key) { 'my_cache_key' }

      it 'uses the cache key' do
        expect(Rails.cache).to receive(:fetch)
          .with(custom_cache_key, expires_in: described_class::DEFAULT_EXPIRES_IN)
          .and_call_original

        described_class.lookup(resource: resource, action: action, cache_key: custom_cache_key) { 'cached_value' }
      end
    end

    context 'with a custom expiration' do
      let(:custom_expiration) { 5.minutes }

      it 'uses the expiration' do
        expect(Rails.cache).to receive(:fetch)
          .with(cache_key, expires_in: custom_expiration)
          .and_call_original

        described_class.lookup(resource: resource, action: action, expires_in: custom_expiration) { 'cached_value' }
      end
    end
  end
end
