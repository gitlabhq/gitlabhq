# frozen_string_literal: true

require 'rails_helper'

describe Gitlab::AnonymousSession, :clean_gitlab_redis_shared_state do
  let(:default_session_id) { '6919a6f1bb119dd7396fadc38fd18d0d' }
  let(:additional_session_id) { '7919a6f1bb119dd7396fadc38fd18d0d' }

  subject { new_anonymous_session }

  def new_anonymous_session(session_id = default_session_id)
    described_class.new('127.0.0.1', session_id: session_id)
  end

  describe '#store_session_id_per_ip' do
    it 'adds session id to proper key' do
      subject.store_session_id_per_ip

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.smembers("session:lookup:ip:gitlab:127.0.0.1")).to eq [default_session_id]
      end
    end

    it 'adds expiration time to key' do
      Timecop.freeze do
        subject.store_session_id_per_ip

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.ttl("session:lookup:ip:gitlab:127.0.0.1")).to eq(24.hours.to_i)
        end
      end
    end

    it 'adds id only once' do
      subject.store_session_id_per_ip
      subject.store_session_id_per_ip

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.smembers("session:lookup:ip:gitlab:127.0.0.1")).to eq [default_session_id]
      end
    end

    context 'when there is already one session' do
      it 'adds session id to proper key' do
        subject.store_session_id_per_ip
        new_anonymous_session(additional_session_id).store_session_id_per_ip

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.smembers("session:lookup:ip:gitlab:127.0.0.1")).to contain_exactly(default_session_id, additional_session_id)
        end
      end
    end
  end

  describe '#stored_sessions' do
    it 'returns all anonymous sessions per ip' do
      Gitlab::Redis::SharedState.with do |redis|
        redis.sadd("session:lookup:ip:gitlab:127.0.0.1", default_session_id)
        redis.sadd("session:lookup:ip:gitlab:127.0.0.1", additional_session_id)
      end

      expect(subject.stored_sessions).to eq(2)
    end
  end

  it 'removes obsolete lookup through ip entries' do
    Gitlab::Redis::SharedState.with do |redis|
      redis.sadd("session:lookup:ip:gitlab:127.0.0.1", default_session_id)
      redis.sadd("session:lookup:ip:gitlab:127.0.0.1", additional_session_id)
    end

    subject.cleanup_session_per_ip_entries

    Gitlab::Redis::SharedState.with do |redis|
      expect(redis.smembers("session:lookup:ip:gitlab:127.0.0.1")).to eq [additional_session_id]
    end
  end
end
