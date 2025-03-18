# frozen_string_literal: true

require 'rspec'

RSpec.describe Gitlab::Sessions::StoreBuilder, feature_category: :system_access do
  let(:cookie_key) { 'cookie' }
  let(:session_cookie_token_prefix) { 'token_prefix' }

  subject(:prepare) { described_class.new(cookie_key, session_cookie_token_prefix).prepare }

  describe '#prepare' do
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
end
