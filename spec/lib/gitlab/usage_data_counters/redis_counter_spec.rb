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

    context 'for every aliased legacy key' do
      let(:key_overrides) { YAML.safe_load(File.read(described_class::KEY_OVERRIDES_PATH)) }

      it 'counter is increased for a legacy key' do
        key_overrides.each do |alias_key, legacy_key|
          expect { subject.increment(alias_key) }.to change { subject.total_count(legacy_key) }.by(1),
            "Incrementing #{alias_key} did not increase #{legacy_key}"
        end
      end
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
