# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::RedisCounter, :clean_gitlab_redis_shared_state do
  let(:redis_key) { 'foobar' }

  subject { Class.new.extend(described_class) }

  describe '.increment' do
    it 'counter is increased' do
      expect do
        subject.increment(redis_key)
      end.to change { subject.total_count(redis_key) }.by(1)
    end
  end

  describe '.increment_by' do
    it 'counter is increased' do
      expect do
        subject.increment_by(redis_key, 3)
      end.to change { subject.total_count(redis_key) }.by(3)
    end
  end
end
