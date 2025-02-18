# frozen_string_literal: true

require 'rspec'

RSpec.describe Gitlab::Sessions::StoreBuilder, feature_category: :system_access do
  let(:cookie_key) { 'cookie' }
  let(:session_cookie_token_prefix) { 'token_prefix' }

  subject(:prepare) { described_class.new(cookie_key, session_cookie_token_prefix).prepare }

  context 'when env var USE_REDIS_CACHE_STORE_AS_SESSION_STORE=true' do
    before do
      stub_env('USE_REDIS_CACHE_STORE_AS_SESSION_STORE', 'true')
    end

    it 'returns Gitlab::Sessions::CacheStore' do
      expect(prepare).to match([
        ::Gitlab::Sessions::CacheStore,
        a_hash_including(
          cache: ActiveSupport::Cache::RedisCacheStore,
          key: cookie_key,
          session_cookie_token_prefix: session_cookie_token_prefix
        )
      ])
    end
  end

  context 'when env var USE_REDIS_CACHE_STORE_AS_SESSION_STORE=false' do
    before do
      stub_env('USE_REDIS_CACHE_STORE_AS_SESSION_STORE', 'false')
    end

    it 'returns Gitlab::Sessions::RedisStore' do
      expect(prepare).to match([
        Gitlab::Sessions::RedisStore,
        a_hash_including(
          redis_server: Gitlab::Redis::Sessions.params.merge(
            namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
            serializer: Gitlab::Sessions::RedisStoreSerializer
          ),
          key: cookie_key,
          session_cookie_token_prefix: session_cookie_token_prefix
        )
      ])
    end
  end
end
