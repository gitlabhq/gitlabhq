require 'spec_helper'

describe Gitlab::Git::Storage::CircuitBreaker, :broken_storage do
  let(:storage_name) { 'default' }
  let(:circuit_breaker) { described_class.new(storage_name, hostname) }
  let(:hostname) { Gitlab::Environment.hostname }
  let(:cache_key) { "storage_accessible:#{storage_name}:#{hostname}" }

  def set_in_redis(name, value)
    Gitlab::Git::Storage.redis.with do |redis|
      redis.zadd(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, cache_key)
      redis.hmset(cache_key, name, value)
    end.first
  end

  before do
    # Override test-settings for the circuitbreaker with something more realistic
    # for these specs.
    stub_storage_settings('default' => {
                            'path' => TestEnv.repos_path
                          },
                          'broken' => {
                            'path' => 'tmp/tests/non-existent-repositories'
                          },
                          'nopath' => { 'path' => nil }
                         )
  end

  describe '.for_storage', :request_store do
    it 'only builds a single circuitbreaker per storage' do
      expect(described_class).to receive(:new).once.and_call_original

      breaker = described_class.for_storage('default')

      expect(breaker).to be_a(described_class)
      expect(described_class.for_storage('default')).to eq(breaker)
    end

    it 'returns a broken circuit breaker for an unknown storage' do
      expect(described_class.for_storage('unknown').circuit_broken?).to be_truthy
    end

    it 'returns a broken circuit breaker when the path is not set' do
      expect(described_class.for_storage('nopath').circuit_broken?).to be_truthy
    end
  end

  describe '#initialize' do
    it 'assigns the settings' do
      expect(circuit_breaker.hostname).to eq(hostname)
      expect(circuit_breaker.storage).to eq('default')
    end
  end

  context 'circuitbreaker settings' do
    before do
      stub_application_setting(circuitbreaker_failure_count_threshold: 0,
                               circuitbreaker_failure_wait_time: 1,
                               circuitbreaker_failure_reset_time: 2,
                               circuitbreaker_storage_timeout: 3,
                               circuitbreaker_access_retries: 4,
                               circuitbreaker_backoff_threshold: 5)
    end

    describe '#failure_count_threshold' do
      it 'reads the value from settings' do
        expect(circuit_breaker.failure_count_threshold).to eq(0)
      end
    end

    describe '#check_interval' do
      it 'reads the value from settings' do
        expect(circuit_breaker.check_interval).to eq(1)
      end
    end

    describe '#failure_reset_time' do
      it 'reads the value from settings' do
        expect(circuit_breaker.failure_reset_time).to eq(2)
      end
    end

    describe '#storage_timeout' do
      it 'reads the value from settings' do
        expect(circuit_breaker.storage_timeout).to eq(3)
      end
    end

    describe '#access_retries' do
      it 'reads the value from settings' do
        expect(circuit_breaker.access_retries).to eq(4)
      end
    end
  end

  describe '#perform' do
    it 'raises the correct exception when the circuit is open' do
      set_in_redis(:last_failure, 1.day.ago.to_f)
      set_in_redis(:failure_count, 999)

      expect { |b| circuit_breaker.perform(&b) }
        .to raise_error do |exception|
        expect(exception).to be_kind_of(Gitlab::Git::Storage::CircuitOpen)
        expect(exception.retry_after).to eq(1800)
      end
    end

    it 'yields the block' do
      expect { |b| circuit_breaker.perform(&b) }
        .to yield_control
    end

    it 'checks if the storage is available' do
      expect(circuit_breaker).to receive(:check_storage_accessible!)
                                   .and_call_original

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
      before do
        stub_feature_flags(git_storage_circuit_breaker: false)
      end

      it 'returns the block without checking accessibility' do
        expect(circuit_breaker).not_to receive(:check_storage_accessible!)

        result = circuit_breaker.perform { 'hello' }

        expect(result).to eq('hello')
      end

      it 'allows enabling the feature using an ENV var' do
        stub_env('GIT_STORAGE_CIRCUIT_BREAKER', 'true')
        expect(circuit_breaker).to receive(:check_storage_accessible!)

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

    it 'is broken when there are too many failures' do
      set_in_redis(:last_failure, 1.day.ago.to_f)
      set_in_redis(:failure_count, 200)

      expect(circuit_breaker.circuit_broken?).to be_truthy
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
end
