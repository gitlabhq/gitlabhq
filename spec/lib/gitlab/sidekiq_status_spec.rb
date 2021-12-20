# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqStatus, :clean_gitlab_redis_queues, :clean_gitlab_redis_shared_state do
  describe '.set' do
    it 'stores the job ID' do
      described_class.set('123')

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(true)
        expect(redis.ttl(key) > 0).to eq(true)
        expect(redis.get(key)).to eq(described_class::DEFAULT_VALUE.to_s)
      end
    end

    it 'allows overriding the expiration time' do
      described_class.set('123', described_class::DEFAULT_EXPIRATION * 2)

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(true)
        expect(redis.ttl(key) > described_class::DEFAULT_EXPIRATION).to eq(true)
        expect(redis.get(key)).to eq(described_class::DEFAULT_VALUE.to_s)
      end
    end

    it 'allows overriding the default value' do
      described_class.set('123', value: 2)

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(true)
        expect(redis.ttl(key) > 0).to eq(true)
        expect(redis.get(key)).to eq('2')
      end
    end
  end

  describe '.unset' do
    it 'removes the job ID' do
      described_class.set('123')
      described_class.unset('123')

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(false)
      end
    end
  end

  describe '.all_completed?' do
    it 'returns true if all jobs have been completed' do
      expect(described_class.all_completed?(%w(123))).to eq(true)
    end

    it 'returns false if a job has not yet been completed' do
      described_class.set('123')

      expect(described_class.all_completed?(%w(123 456))).to eq(false)
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
      expect(described_class.num_running(%w(123))).to eq(0)
    end

    it 'returns 2 if two jobs are still running' do
      described_class.set('123')
      described_class.set('456')

      expect(described_class.num_running(%w(123 456 789))).to eq(2)
    end
  end

  describe '.num_completed' do
    it 'returns 1 if all jobs have been completed' do
      expect(described_class.num_completed(%w(123))).to eq(1)
    end

    it 'returns 1 if a job has not yet been completed' do
      described_class.set('123')
      described_class.set('456')

      expect(described_class.num_completed(%w(123 456 789))).to eq(1)
    end
  end

  describe '.key_for' do
    it 'returns the key for a job ID' do
      key = described_class.key_for('123')

      expect(key).to be_an_instance_of(String)
      expect(key).to include('123')
    end
  end

  describe '.completed_jids' do
    it 'returns the completed job' do
      expect(described_class.completed_jids(%w(123))).to eq(['123'])
    end

    it 'returns only the jobs completed' do
      described_class.set('123')
      described_class.set('456')

      expect(described_class.completed_jids(%w(123 456 789))).to eq(['789'])
    end
  end

  describe '.job_status' do
    it 'returns an array of boolean values' do
      described_class.set('123')
      described_class.set('456')
      described_class.unset('123')

      expect(described_class.job_status(%w(123 456 789))).to eq([false, true, false])
    end

    it 'handles an empty array' do
      expect(described_class.job_status([])).to eq([])
    end

    context 'when log_implicit_sidekiq_status_calls is enabled' do
      it 'logs keys that contained the default value' do
        described_class.set('123', value: 2)
        described_class.set('456')
        described_class.set('012')

        expect(Sidekiq.logger).to receive(:info).with(message: described_class::DEFAULT_VALUE_MESSAGE,
                                                      keys: [described_class.key_for('456'), described_class.key_for('012')])

        expect(described_class.job_status(%w(123 456 789 012))).to eq([true, true, false, true])
      end
    end

    context 'when log_implicit_sidekiq_status_calls is disabled' do
      before do
        stub_feature_flags(log_implicit_sidekiq_status_calls: false)
      end

      it 'does not perform any logging' do
        described_class.set('123', value: 2)
        described_class.set('456')

        expect(Sidekiq.logger).not_to receive(:info)

        expect(described_class.job_status(%w(123 456 789))).to eq([true, true, false])
      end
    end
  end
end
