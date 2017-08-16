require 'spec_helper'

describe Gitlab::Git::Storage::CircuitBreaker, clean_gitlab_redis_shared_state: true, broken_storage: true do
  let(:storage_name) { 'default' }
  let(:circuit_breaker) { described_class.new(storage_name) }
  let(:hostname) { Gitlab::Environment.hostname }
  let(:cache_key) { "storage_accessible:#{storage_name}:#{hostname}" }

  before do
    # Override test-settings for the circuitbreaker with something more realistic
    # for these specs.
    stub_storage_settings('default' => {
                            'path' => TestEnv.repos_path,
                            'failure_count_threshold' => 10,
                            'failure_wait_time' => 30,
                            'failure_reset_time' => 1800,
                            'storage_timeout' => 5
                          },
                          'broken' => {
                            'path' => 'tmp/tests/non-existent-repositories',
                            'failure_count_threshold' => 10,
                            'failure_wait_time' => 30,
                            'failure_reset_time' => 1800,
                            'storage_timeout' => 5
                          }
                         )
  end

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

  describe '.reset_all!' do
    it 'clears all entries form redis' do
      set_in_redis(:failure_count, 10)

      described_class.reset_all!

      key_exists = Gitlab::Git::Storage.redis.with { |redis| redis.exists(cache_key) }

      expect(key_exists).to be_falsey
    end
  end

  describe '.for_storage' do
    it 'only builds a single circuitbreaker per storage' do
      expect(described_class).to receive(:new).once.and_call_original

      breaker = described_class.for_storage('default')

      expect(breaker).to be_a(described_class)
      expect(described_class.for_storage('default')).to eq(breaker)
    end
  end

  describe '#initialize' do
    it 'assigns the settings' do
      expect(circuit_breaker.hostname).to eq(hostname)
      expect(circuit_breaker.storage).to eq('default')
      expect(circuit_breaker.storage_path).to eq(TestEnv.repos_path)
      expect(circuit_breaker.failure_count_threshold).to eq(10)
      expect(circuit_breaker.failure_wait_time).to eq(30)
      expect(circuit_breaker.failure_reset_time).to eq(1800)
      expect(circuit_breaker.storage_timeout).to eq(5)
    end
  end

  describe '#perform' do
    it 'raises an exception with retry time when the circuit is open' do
      allow(circuit_breaker).to receive(:circuit_broken?).and_return(true)

      expect { |b| circuit_breaker.perform(&b) }
        .to raise_error(Gitlab::Git::Storage::CircuitOpen)
    end

    it 'yields the block' do
      expect { |b| circuit_breaker.perform(&b) }
        .to yield_control
    end

    it 'checks if the storage is available' do
      expect(circuit_breaker).to receive(:check_storage_accessible!)

      circuit_breaker.perform { 'hello world' }
    end

    it 'returns the value of the block' do
      result = circuit_breaker.perform { 'return value' }

      expect(result).to eq('return value')
    end

    it 'raises possible errors' do
      expect { circuit_breaker.perform { raise Rugged::OSError.new('Broken') } }
        .to raise_error(Rugged::OSError)
    end

    context 'with the feature disabled' do
      it 'returns the block without checking accessibility' do
        stub_feature_flags(git_storage_circuit_breaker: false)

        expect(circuit_breaker).not_to receive(:circuit_broken?)

        result = circuit_breaker.perform { 'hello' }

        expect(result).to eq('hello')
      end
    end
  end

  describe '#circuit_broken?' do
    it 'is working when there is no last failure' do
      set_in_redis(:last_failure, nil)
      set_in_redis(:failure_count, 0)

      expect(circuit_breaker.circuit_broken?).to be_falsey
    end

    it 'is broken when there was a recent failure' do
      Timecop.freeze do
        set_in_redis(:last_failure, 1.second.ago.to_f)
        set_in_redis(:failure_count, 1)

        expect(circuit_breaker.circuit_broken?).to be_truthy
      end
    end

    it 'is broken when there are too many failures' do
      set_in_redis(:last_failure, 1.day.ago.to_f)
      set_in_redis(:failure_count, 200)

      expect(circuit_breaker.circuit_broken?).to be_truthy
    end

    context 'the `failure_wait_time` is set to 0' do
      before do
        stub_storage_settings('default' => {
                                'failure_wait_time' => 0,
                                'path' => TestEnv.repos_path
                              })
      end

      it 'is working even when there is a recent failure' do
        Timecop.freeze do
          set_in_redis(:last_failure, 0.seconds.ago.to_f)
          set_in_redis(:failure_count, 1)

          expect(circuit_breaker.circuit_broken?).to be_falsey
        end
      end
    end
  end

  describe "storage_available?" do
    context 'the storage is available' do
      it 'tracks that the storage was accessible an raises the error' do
        expect(circuit_breaker).to receive(:track_storage_accessible)

        circuit_breaker.storage_available?
      end

      it 'only performs the check once' do
        expect(Gitlab::Git::Storage::ForkedStorageCheck)
          .to receive(:storage_available?).once.and_call_original

        2.times { circuit_breaker.storage_available? }
      end
    end

    context 'storage is not available' do
      let(:storage_name) { 'broken' }

      it 'tracks that the storage was inaccessible' do
        expect(circuit_breaker).to receive(:track_storage_inaccessible)

        circuit_breaker.storage_available?
      end
    end
  end

  describe '#check_storage_accessible!' do
    it 'raises an exception with retry time when the circuit is open' do
      allow(circuit_breaker).to receive(:circuit_broken?).and_return(true)

      expect { circuit_breaker.check_storage_accessible! }
        .to raise_error do |exception|
        expect(exception).to be_kind_of(Gitlab::Git::Storage::CircuitOpen)
        expect(exception.retry_after).to eq(30)
      end
    end

    context 'the storage is not available' do
      let(:storage_name) { 'broken' }

      it 'raises an error' do
        expect(circuit_breaker).to receive(:track_storage_inaccessible)

        expect { circuit_breaker.check_storage_accessible! }
          .to raise_error do |exception|
          expect(exception).to be_kind_of(Gitlab::Git::Storage::Inaccessible)
          expect(exception.retry_after).to eq(30)
        end
      end
    end
  end

  describe '#track_storage_inaccessible' do
    around(:each) do |example|
      Timecop.freeze

      example.run

      Timecop.return
    end

    it 'records the failure time in redis' do
      circuit_breaker.track_storage_inaccessible

      failure_time = value_from_redis(:last_failure)

      expect(Time.at(failure_time.to_i)).to be_within(1.second).of(Time.now)
    end

    it 'sets the failure time on the breaker without reloading' do
      circuit_breaker.track_storage_inaccessible

      expect(circuit_breaker).not_to receive(:get_failure_info)
      expect(circuit_breaker.last_failure).to eq(Time.now)
    end

    it 'increments the failure count in redis' do
      set_in_redis(:failure_count, 10)

      circuit_breaker.track_storage_inaccessible

      expect(value_from_redis(:failure_count).to_i).to be(11)
    end

    it 'increments the failure count on the breaker without reloading' do
      set_in_redis(:failure_count, 10)

      circuit_breaker.track_storage_inaccessible

      expect(circuit_breaker).not_to receive(:get_failure_info)
      expect(circuit_breaker.failure_count).to eq(11)
    end
  end

  describe '#track_storage_accessible' do
    it 'sets the failure count to zero in redis' do
      set_in_redis(:failure_count, 10)

      circuit_breaker.track_storage_accessible

      expect(value_from_redis(:failure_count).to_i).to be(0)
    end

    it 'sets the failure count to zero on the breaker without reloading' do
      set_in_redis(:failure_count, 10)

      circuit_breaker.track_storage_accessible

      expect(circuit_breaker).not_to receive(:get_failure_info)
      expect(circuit_breaker.failure_count).to eq(0)
    end

    it 'removes the last failure time from redis' do
      set_in_redis(:last_failure, Time.now.to_i)

      circuit_breaker.track_storage_accessible

      expect(circuit_breaker).not_to receive(:get_failure_info)
      expect(circuit_breaker.last_failure).to be_nil
    end

    it 'removes the last failure time from the breaker without reloading' do
      set_in_redis(:last_failure, Time.now.to_i)

      circuit_breaker.track_storage_accessible

      expect(value_from_redis(:last_failure)).to be_empty
    end

    it 'wont connect to redis when there are no failures' do
      expect(Gitlab::Git::Storage.redis).to receive(:with).once
                                              .and_call_original
      expect(circuit_breaker).to receive(:track_storage_accessible)
                           .and_call_original

      circuit_breaker.track_storage_accessible
    end
  end

  describe '#no_failures?' do
    it 'is false when a failure was tracked' do
      set_in_redis(:last_failure, Time.now.to_i)
      set_in_redis(:failure_count, 1)

      expect(circuit_breaker.no_failures?).to be_falsey
    end
  end

  describe '#last_failure' do
    it 'returns the last failure time' do
      time = Time.parse("2017-05-26 17:52:30")
      set_in_redis(:last_failure, time.to_i)

      expect(circuit_breaker.last_failure).to eq(time)
    end
  end

  describe '#failure_count' do
    it 'returns the failure count' do
      set_in_redis(:failure_count, 7)

      expect(circuit_breaker.failure_count).to eq(7)
    end
  end

  describe '#cache_key' do
    it 'includes storage and host' do
      expect(circuit_breaker.cache_key).to eq(cache_key)
    end
  end
end
