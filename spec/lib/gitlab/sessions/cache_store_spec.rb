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

  describe '#find_session' do
    let(:redis_cache_store) do
      ActiveSupport::Cache::RedisCacheStore.new(
        namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
        redis: Gitlab::Redis::Sessions,
        coder: Gitlab::Sessions::CacheStoreCoder
      )
    end

    let(:cache_store) { described_class.new(nil, { cache: redis_cache_store }) }
    let(:session_id) { Rack::Session::SessionId.new(SecureRandom.hex(16)) }
    let(:session_data) { { 'user_id' => 123, 'nested' => { 'key' => 'value' } } }
    let(:env) { ActionDispatch::Request.new(Rack::MockRequest.env_for('/')) }

    before do
      redis_cache_store.write(session_id.private_id, session_data)
    end

    it 'stores a deep copy of the original session data in the env' do
      _sid, data = cache_store.find_session(env, session_id)

      original_sid, original_data = env.get_header(described_class::ORIGINAL_SESSION_KEY)

      expect(original_sid).to eq(session_id)
      expect(original_data).to eq(session_data)
      expect(original_data).not_to be(data)
      expect(original_data['nested']).not_to be(data['nested'])
    end
  end

  describe '#write_session', :freeze_time do
    let(:redis_cache_store) { instance_double(ActiveSupport::Cache::RedisCacheStore, options: {}) }
    let(:cache_store) { described_class.new(nil, { cache: redis_cache_store }) }

    let(:env) { ActionDispatch::Request.new(Rack::MockRequest.env_for('/')) }
    let(:session_id) { Rack::Session::SessionId.new(SecureRandom.hex(16)) }
    let(:session_data) { { 'some_key' => 'some_value' } }
    let(:redis_expiry) { 999 }

    subject(:write_session) { cache_store.write_session(env, session_id, session_data, { redis_expiry: redis_expiry }) }

    it 'uses the redis_expiry option as the Redis TTL and stamps last_write_at' do
      expect(redis_cache_store).to receive(:write).with(
        session_id.private_id,
        session_data.merge(described_class::LAST_WRITE_AT_KEY => Time.now.to_i),
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

    context 'when session data has not changed' do
      before do
        session_data[described_class::LAST_WRITE_AT_KEY] = last_write_at if last_write_at
        env.set_header(described_class::ORIGINAL_SESSION_KEY, [session_id, session_data.deep_dup])
      end

      context 'when last write was recent' do
        let(:last_write_at) { 5.minutes.ago.to_i }

        it 'skips the write and returns the session id' do
          expect(redis_cache_store).not_to receive(:write)

          expect(write_session).to eq(session_id)
        end

        context 'when throttle_session_writes is disabled' do
          before do
            stub_feature_flags(throttle_session_writes: false)
          end

          it 'writes the session with an updated timestamp' do
            expect(redis_cache_store).to receive(:write).with(
              session_id.private_id,
              session_data.merge(described_class::LAST_WRITE_AT_KEY => Time.now.to_i),
              expires_in: redis_expiry
            )

            expect(write_session).to eq(session_id)
          end
        end
      end

      context 'when last write was more than an hour ago' do
        let(:last_write_at) { 2.hours.ago.to_i }

        it 'writes the session with an updated timestamp' do
          expect(redis_cache_store).to receive(:write).with(
            session_id.private_id,
            session_data.merge(described_class::LAST_WRITE_AT_KEY => Time.now.to_i),
            expires_in: redis_expiry
          )

          expect(write_session).to eq(session_id)
        end
      end

      context 'when there is no last_write_at timestamp' do
        let(:last_write_at) { nil }

        it 'writes the session with a new timestamp' do
          expect(redis_cache_store).to receive(:write).with(
            session_id.private_id,
            session_data.merge(described_class::LAST_WRITE_AT_KEY => Time.now.to_i),
            expires_in: redis_expiry
          )

          expect(write_session).to eq(session_id)
        end
      end
    end

    context 'when session id has changed' do
      let(:old_session_id) { Rack::Session::SessionId.new(SecureRandom.hex(16)) }

      before do
        session_data[described_class::LAST_WRITE_AT_KEY] = 1.minute.ago.to_i
        env.set_header(described_class::ORIGINAL_SESSION_KEY, [old_session_id, session_data.deep_dup])
      end

      it 'writes the session regardless of last_write_at' do
        expect(redis_cache_store).to receive(:write).with(
          session_id.private_id,
          session_data.merge(described_class::LAST_WRITE_AT_KEY => Time.now.to_i),
          expires_in: redis_expiry
        )

        expect(write_session).to eq(session_id)
      end
    end

    context 'when session data has changed' do
      before do
        env.set_header(described_class::ORIGINAL_SESSION_KEY, [
          session_id,
          { 'some_key' => 'old_value', described_class::LAST_WRITE_AT_KEY => 1.minute.ago.to_i }
        ])
        session_data[described_class::LAST_WRITE_AT_KEY] = 1.minute.ago.to_i
      end

      it 'writes the session regardless of last_write_at' do
        expect(redis_cache_store).to receive(:write).with(
          session_id.private_id,
          session_data.merge(described_class::LAST_WRITE_AT_KEY => Time.now.to_i),
          expires_in: redis_expiry
        )

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
