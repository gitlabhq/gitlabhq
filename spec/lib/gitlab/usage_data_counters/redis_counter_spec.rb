# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::RedisCounter, :clean_gitlab_redis_shared_state do
  context 'when redis_key is not defined' do
    subject do
      Class.new.extend(described_class)
    end

    describe '.increment' do
      it 'raises a NotImplementedError exception' do
        expect { subject.increment}.to raise_error(NotImplementedError)
      end
    end

    describe '.total_count' do
      it 'raises a NotImplementedError exception' do
        expect { subject.total_count}.to raise_error(NotImplementedError)
      end
    end
  end

  context 'when redis_key is defined' do
    subject do
      counter_module = described_class

      Class.new do
        extend counter_module

        def self.redis_counter_key
          'foo_redis_key'
        end
      end
    end

    describe '.increment' do
      it 'increments the web ide commits counter by 1' do
        expect do
          subject.increment
        end.to change { subject.total_count }.from(0).to(1)
      end
    end

    describe '.total_count' do
      it 'returns the total amount of web ide commits' do
        subject.increment
        subject.increment

        expect(subject.total_count).to eq(2)
      end
    end
  end
end
