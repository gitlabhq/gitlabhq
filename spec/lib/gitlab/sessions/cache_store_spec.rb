# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Sessions::CacheStore, feature_category: :cell do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize' do
    let(:default_expiry) { 999 }
    let(:cache_store) do
      described_class.new(nil, {
        cache: ActiveSupport::Cache::RedisCacheStore.new(
          namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
          redis: Gitlab::Redis::Sessions,
          expires_in: default_expiry,
          coder: Gitlab::Sessions::CacheStoreCoder
        )
      })
    end

    it 'sets the correct default options' do
      expect(cache_store.default_options).to include({
        expire_after: nil,
        redis_expiry: default_expiry
      })
    end
  end

  describe '#write_session' do
    let(:redis_cache_store) { instance_double(ActiveSupport::Cache::RedisCacheStore, options: {}) }
    let(:cache_store) { described_class.new(nil, { cache: redis_cache_store }) }

    let(:session_id) { Rack::Session::SessionId.new(SecureRandom.hex(16)) }
    let(:session_data) { { some_key: 'some_value' } }
    let(:redis_expiry) { 999 }

    subject(:write_session) { cache_store.write_session(nil, session_id, session_data, { redis_expiry: redis_expiry }) }

    it 'uses the redis_expiry option as the Redis TTL' do
      expect(redis_cache_store).to receive(:write).with(
        session_id.private_id,
        session_data,
        expires_in: redis_expiry
      )

      expect(write_session).to eq(session_id)
    end

    context 'when session is nil' do
      let(:session_data) { nil }

      it 'deletes the key from Redis' do
        expect(redis_cache_store).to receive(:delete).with(session_id.private_id)

        expect(write_session).to eq(session_id)
      end
    end
  end

  describe '#generate_sid' do
    let(:redis_store) do
      described_class.new(Rails.application, { session_cookie_token_prefix: session_cookie_token_prefix })
    end

    context 'when passing `session_cookie_token_prefix` in options' do
      where(:prefix, :calculated_prefix) do
        nil              | ''
        ''               | ''
        'random_prefix_' | 'random_prefix_-'
        '_random_prefix' | '_random_prefix-'
      end

      with_them do
        let(:session_cookie_token_prefix) { prefix }

        it 'generates sid that is prefixed with the configured prefix' do
          generated_sid = redis_store.generate_sid
          expect(generated_sid).to be_a Rack::Session::SessionId
          expect(generated_sid.public_id).to match(/^#{calculated_prefix}[a-z0-9]{32}$/)
        end
      end
    end

    context 'when not passing `session_cookie_token_prefix` in options' do
      let(:redis_store) { described_class.new(Rails.application) }

      it 'generates sid that is not prefixed' do
        generated_sid = redis_store.generate_sid
        expect(generated_sid).to be_a Rack::Session::SessionId
        expect(generated_sid.public_id).to match(/^[a-z0-9]{32}$/)
      end
    end
  end
end
