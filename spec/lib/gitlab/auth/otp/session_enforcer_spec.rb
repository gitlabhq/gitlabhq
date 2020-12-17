# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Otp::SessionEnforcer, :clean_gitlab_redis_shared_state do
  let_it_be(:key) { create(:key)}

  describe '#update_session' do
    it 'registers a session in Redis' do
      redis = double(:redis)
      expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis)

      expect(redis).to(
        receive(:setex)
          .with("#{described_class::OTP_SESSIONS_NAMESPACE}:#{key.id}",
                described_class::DEFAULT_EXPIRATION,
                true)
          .once)

      described_class.new(key).update_session
    end
  end

  describe '#access_restricted?' do
    subject { described_class.new(key).access_restricted? }

    context 'with existing session' do
      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set("#{described_class::OTP_SESSIONS_NAMESPACE}:#{key.id}", true )
        end
      end

      it { is_expected.to be_falsey }
    end

    context 'without an existing session' do
      it { is_expected.to be_truthy }
    end
  end
end
