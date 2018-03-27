require 'spec_helper'

describe Gitlab::Git::Storage::Checker, :clean_gitlab_redis_shared_state do
  let(:storage_name) { 'default' }
  let(:hostname) { Gitlab::Environment.hostname }
  let(:cache_key) { "storage_accessible:#{storage_name}:#{hostname}" }

  subject(:checker) { described_class.new(storage_name) }

  def value_from_redis(name)
    Gitlab::Git::Storage.redis.with do |redis|
      redis.hmget(cache_key, name)
    end.first
  end

  def set_in_redis(name, value)
    Gitlab::Git::Storage.redis.with do |redis|
      redis.hmset(cache_key, name, value)
    end.first
  end

  describe '.check_all' do
    it 'calls a check for each storage' do
      fake_checker_default = double
      fake_checker_broken = double
      fake_logger = fake_logger

      expect(described_class).to receive(:new).with('default', fake_logger) { fake_checker_default }
      expect(described_class).to receive(:new).with('broken', fake_logger) { fake_checker_broken }
      expect(fake_checker_default).to receive(:check_with_lease)
      expect(fake_checker_broken).to receive(:check_with_lease)

      described_class.check_all(fake_logger)
    end

    context 'with broken storage', :broken_storage do
      it 'returns the results' do
        expected_result = [
          { storage: 'default', success: true },
          { storage: 'broken', success: false }
        ]

        expect(described_class.check_all).to eq(expected_result)
      end
    end
  end

  describe '#initialize' do
    it 'assigns the settings' do
      expect(checker.hostname).to eq(hostname)
      expect(checker.storage).to eq('default')
      expect(checker.storage_path).to eq(TestEnv.repos_path)
    end
  end

  describe '#check_with_lease' do
    it 'only allows one check at a time' do
      expect(checker).to receive(:check).once { sleep 1 }

      thread = Thread.new { checker.check_with_lease }
      checker.check_with_lease
      thread.join
    end

    it 'returns a result hash' do
      expect(checker.check_with_lease).to eq(storage: 'default', success: true)
    end
  end

  describe '#check' do
    it 'tracks that the storage was accessible' do
      set_in_redis(:failure_count, 10)
      set_in_redis(:last_failure, Time.now.to_f)

      checker.check

      expect(value_from_redis(:failure_count).to_i).to eq(0)
      expect(value_from_redis(:last_failure)).to be_empty
      expect(value_from_redis(:first_failure)).to be_empty
    end

    it 'calls the check with the correct arguments' do
      stub_application_setting(circuitbreaker_storage_timeout: 30,
                               circuitbreaker_access_retries: 3)

      expect(Gitlab::Git::Storage::ForkedStorageCheck)
        .to receive(:storage_available?).with(TestEnv.repos_path, 30, 3)
              .and_call_original

      checker.check
    end

    it 'returns `true`' do
      expect(checker.check).to eq(true)
    end

    it 'maintains known storage keys' do
      Timecop.freeze do
        # Insert an old key to expire
        old_entry = Time.now.to_i - 3.days.to_i
        Gitlab::Git::Storage.redis.with do |redis|
          redis.zadd(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, old_entry, 'to_be_removed')
        end

        checker.check

        known_keys = Gitlab::Git::Storage.redis.with do |redis|
          redis.zrange(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, -1)
        end

        expect(known_keys).to contain_exactly(cache_key)
      end
    end

    context 'the storage is not available', :broken_storage do
      let(:storage_name) { 'broken' }

      it 'tracks that the storage was inaccessible' do
        Timecop.freeze do
          expect { checker.check }.to change { value_from_redis(:failure_count).to_i }.by(1)

          expect(value_from_redis(:last_failure)).not_to be_empty
          expect(value_from_redis(:first_failure)).not_to be_empty
        end
      end

      it 'returns `false`' do
        expect(checker.check).to eq(false)
      end
    end
  end
end
