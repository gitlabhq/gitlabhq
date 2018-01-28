require 'spec_helper'

describe Gitlab::SidekiqStatus do
  describe '.set', :clean_gitlab_redis_shared_state do
    it 'stores the job ID' do
      described_class.set('123')

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(true)
        expect(redis.ttl(key) > 0).to eq(true)
      end
    end
  end

  describe '.unset', :clean_gitlab_redis_shared_state do
    it 'removes the job ID' do
      described_class.set('123')
      described_class.unset('123')

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(false)
      end
    end
  end

  describe '.all_completed?', :clean_gitlab_redis_shared_state do
    it 'returns true if all jobs have been completed' do
      expect(described_class.all_completed?(%w(123))).to eq(true)
    end

    it 'returns false if a job has not yet been completed' do
      described_class.set('123')

      expect(described_class.all_completed?(%w(123 456))).to eq(false)
    end
  end

  describe '.running?', :clean_gitlab_redis_shared_state do
    it 'returns true if job is running' do
      described_class.set('123')

      expect(described_class.running?('123')).to be(true)
    end

    it 'returns false if job is not found' do
      expect(described_class.running?('123')).to be(false)
    end
  end

  describe '.num_running', :clean_gitlab_redis_shared_state do
    it 'returns 0 if all jobs have been completed' do
      expect(described_class.num_running(%w(123))).to eq(0)
    end

    it 'returns 2 if two jobs are still running' do
      described_class.set('123')
      described_class.set('456')

      expect(described_class.num_running(%w(123 456 789))).to eq(2)
    end
  end

  describe '.num_completed', :clean_gitlab_redis_shared_state do
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

  describe 'completed', :clean_gitlab_redis_shared_state do
    it 'returns the completed job' do
      expect(described_class.completed_jids(%w(123))).to eq(['123'])
    end

    it 'returns only the jobs completed' do
      described_class.set('123')
      described_class.set('456')

      expect(described_class.completed_jids(%w(123 456 789))).to eq(['789'])
    end
  end
end
