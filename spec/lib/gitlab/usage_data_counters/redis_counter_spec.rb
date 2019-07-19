# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::RedisCounter, :clean_gitlab_redis_shared_state do
  let(:redis_key) { 'foobar' }

  subject { Class.new.extend(described_class) }

  before do
    stub_application_setting(usage_ping_enabled: setting_value)
  end

  context 'when usage_ping is disabled' do
    let(:setting_value) { false }

    it 'counter is not increased' do
      expect do
        subject.increment(redis_key)
      end.not_to change { subject.total_count(redis_key) }
    end
  end

  context 'when usage_ping is enabled' do
    let(:setting_value) { true }

    it 'counter is increased' do
      expect do
        subject.increment(redis_key)
      end.to change { subject.total_count(redis_key) }.by(1)
    end
  end
end
