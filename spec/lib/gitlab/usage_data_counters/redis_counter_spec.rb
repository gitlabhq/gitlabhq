# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::RedisCounter, :clean_gitlab_redis_shared_state do
  let(:redis_key) { 'foobar' }

  subject { Class.new.extend(described_class) }

  before do
    allow(::ServicePing::ServicePingSettings).to receive(:enabled?).and_return(service_ping_enabled)
  end

  describe '.increment' do
    context 'when usage_ping is disabled' do
      let(:service_ping_enabled) { false }

      it 'counter is not increased' do
        expect do
          subject.increment(redis_key)
        end.not_to change { subject.total_count(redis_key) }
      end
    end

    context 'when usage_ping is enabled' do
      let(:service_ping_enabled) { true }

      it 'counter is increased' do
        expect do
          subject.increment(redis_key)
        end.to change { subject.total_count(redis_key) }.by(1)
      end
    end
  end

  describe '.increment_by' do
    context 'when usage_ping is disabled' do
      let(:service_ping_enabled) { false }

      it 'counter is not increased' do
        expect do
          subject.increment_by(redis_key, 3)
        end.not_to change { subject.total_count(redis_key) }
      end
    end

    context 'when usage_ping is enabled' do
      let(:service_ping_enabled) { true }

      it 'counter is increased' do
        expect do
          subject.increment_by(redis_key, 3)
        end.to change { subject.total_count(redis_key) }.by(3)
      end
    end
  end
end
