# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqStatus, :clean_gitlab_redis_queues,
  :clean_gitlab_redis_shared_state, :clean_gitlab_redis_cluster_shared_state do
  shared_examples 'tracking status in redis' do
    describe '.set' do
      it 'stores the job ID' do
        described_class.set('123')

        key = described_class.key_for('123')

        with_redis do |redis|
          expect(redis.exists?(key)).to eq(true)
          expect(redis.ttl(key) > 0).to eq(true)
          expect(redis.get(key)).to eq('1')
        end
      end

      it 'allows overriding the expiration time' do
        described_class.set('123', described_class::DEFAULT_EXPIRATION * 2)

        key = described_class.key_for('123')

        with_redis do |redis|
          expect(redis.exists?(key)).to eq(true)
          expect(redis.ttl(key) > described_class::DEFAULT_EXPIRATION).to eq(true)
          expect(redis.get(key)).to eq('1')
        end
      end

      it 'does not store anything with a nil expiry' do
        described_class.set('123', nil)

        key = described_class.key_for('123')

        with_redis do |redis|
          expect(redis.exists?(key)).to eq(false)
        end
      end
    end

    describe '.unset' do
      it 'removes the job ID' do
        described_class.set('123')
        described_class.unset('123')

        key = described_class.key_for('123')

        with_redis do |redis|
          expect(redis.exists?(key)).to eq(false)
        end
      end
    end

    describe '.expire' do
      it 'refreshes the expiration time if key is present' do
        described_class.set('123', 1.minute)
        described_class.expire('123', 1.hour)

        key = described_class.key_for('123')

        with_redis do |redis|
          expect(redis.exists?(key)).to eq(true)
          expect(redis.ttl(key) > 5.minutes).to eq(true)
        end
      end

      it 'does nothing if key is not present' do
        described_class.expire('123', 1.minute)

        key = described_class.key_for('123')

        with_redis do |redis|
          expect(redis.exists?(key)).to eq(false)
          expect(redis.ttl(key)).to eq(-2)
        end
      end
    end

    describe '.all_completed?' do
      it 'returns true if all jobs have been completed' do
        expect(described_class.all_completed?(%w[123])).to eq(true)
      end

      it 'returns false if a job has not yet been completed' do
        described_class.set('123')

        expect(described_class.all_completed?(%w[123 456])).to eq(false)
      end
    end

    describe '.running?' do
      it 'returns true if job is running' do
        described_class.set('123')

        expect(described_class.running?('123')).to be(true)
      end

      it 'returns false if job is not found' do
        expect(described_class.running?('123')).to be(false)
      end
    end

    describe '.num_running' do
      it 'returns 0 if all jobs have been completed' do
        expect(described_class.num_running(%w[123])).to eq(0)
      end

      it 'returns 2 if two jobs are still running' do
        described_class.set('123')
        described_class.set('456')

        expect(described_class.num_running(%w[123 456 789])).to eq(2)
      end
    end

    describe '.num_completed' do
      it 'returns 1 if all jobs have been completed' do
        expect(described_class.num_completed(%w[123])).to eq(1)
      end

      it 'returns 1 if a job has not yet been completed' do
        described_class.set('123')
        described_class.set('456')

        expect(described_class.num_completed(%w[123 456 789])).to eq(1)
      end
    end

    describe '.completed_jids' do
      it 'returns the completed job' do
        expect(described_class.completed_jids(%w[123])).to eq(['123'])
      end

      it 'returns only the jobs completed' do
        described_class.set('123')
        described_class.set('456')

        expect(described_class.completed_jids(%w[123 456 789])).to eq(['789'])
      end
    end

    describe '.job_status' do
      it 'returns an array of boolean values' do
        described_class.set('123')
        described_class.set('456')
        described_class.unset('123')

        expect(described_class.job_status(%w[123 456 789])).to eq([false, true, false])
      end

      it 'handles an empty array' do
        expect(described_class.job_status([])).to eq([])
      end
    end
  end

  context 'with multi-store feature flags turned on' do
    def with_redis(&block)
      Gitlab::Redis::SharedState.with(&block)
    end

    it 'uses Gitlab::Redis::SharedState.with' do
      expect(Gitlab::Redis::SharedState).to receive(:with).and_call_original
      expect(Sidekiq).not_to receive(:redis)

      described_class.job_status(%w[123 456 789])
    end

    it_behaves_like 'tracking status in redis'
  end

  context 'when both multi-store feature flags are off' do
    def with_redis(&block)
      Sidekiq.redis(&block)
    end

    before do
      stub_feature_flags(use_primary_and_secondary_stores_for_sidekiq_status: false)
      stub_feature_flags(use_primary_store_as_default_for_sidekiq_status: false)
    end

    it 'uses Sidekiq.redis' do
      expect(Sidekiq).to receive(:redis).and_call_original
      expect(Gitlab::Redis::SharedState).not_to receive(:with)

      described_class.job_status(%w[123 456 789])
    end

    it_behaves_like 'tracking status in redis'
  end

  describe '.key_for' do
    it 'returns the key for a job ID' do
      key = described_class.key_for('123')

      expect(key).to be_an_instance_of(String)
      expect(key).to include('123')
    end
  end
end
