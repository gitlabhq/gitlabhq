require 'spec_helper'

describe Gitlab::SidekiqStatus do
  describe '.set', :redis do
    it 'stores the job ID' do
      described_class.set('123')

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(true)
        expect(redis.ttl(key) > 0).to eq(true)
      end
    end
  end

  describe '.unset', :redis do
    it 'removes the job ID' do
      described_class.set('123')
      described_class.unset('123')

      key = described_class.key_for('123')

      Sidekiq.redis do |redis|
        expect(redis.exists(key)).to eq(false)
      end
    end
  end

  describe '.all_completed?', :redis do
    it 'returns true if all jobs have been completed' do
      expect(described_class.all_completed?(%w(123))).to eq(true)
    end

    it 'returns false if a job has not yet been completed' do
      described_class.set('123')

      expect(described_class.all_completed?(%w(123 456))).to eq(false)
    end
  end

  describe '.key_for' do
    it 'returns the key for a job ID' do
      key = described_class.key_for('123')

      expect(key).to be_an_instance_of(String)
      expect(key).to include('123')
    end
  end
end
