require 'spec_helper'

describe Gitlab::Git::Storage::FailureInfo, :broken_storage do
  let(:storage_name) { 'default' }
  let(:hostname) { Gitlab::Environment.hostname }
  let(:cache_key) { "storage_accessible:#{storage_name}:#{hostname}" }

  def value_from_redis(name)
    Gitlab::Git::Storage.redis.with do |redis|
      redis.hmget(cache_key, name)
    end.first
  end

  def set_in_redis(name, value)
    Gitlab::Git::Storage.redis.with do |redis|
      redis.zadd(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, cache_key)
      redis.hmset(cache_key, name, value)
    end.first
  end

  describe '.reset_all!' do
    it 'clears all entries form redis' do
      set_in_redis(:failure_count, 10)

      described_class.reset_all!

      key_exists = Gitlab::Git::Storage.redis.with { |redis| redis.exists(cache_key) }

      expect(key_exists).to be_falsey
    end

    it 'does not break when there are no keys in redis' do
      expect { described_class.reset_all! }.not_to raise_error
    end
  end

  describe '.load' do
    it 'loads failure information for a storage on a host' do
      first_failure = Time.parse("2017-11-14 17:52:30")
      last_failure = Time.parse("2017-11-14 18:54:37")
      failure_count = 11

      set_in_redis(:first_failure, first_failure.to_i)
      set_in_redis(:last_failure, last_failure.to_i)
      set_in_redis(:failure_count, failure_count.to_i)

      info = described_class.load(cache_key)

      expect(info.first_failure).to eq(first_failure)
      expect(info.last_failure).to eq(last_failure)
      expect(info.failure_count).to eq(failure_count)
    end
  end

  describe '#no_failures?' do
    it 'is true when there are no failures' do
      info = described_class.new(nil, nil, 0)

      expect(info.no_failures?).to be_truthy
    end

    it 'is false when there are failures' do
      info = described_class.new(Time.parse("2017-11-14 17:52:30"),
                                 Time.parse("2017-11-14 18:54:37"),
                                 20)

      expect(info.no_failures?).to be_falsy
    end
  end
end
