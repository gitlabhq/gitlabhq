# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JobWaiter, :redis, feature_category: :shared do
  describe '.notify' do
    let(:key) { described_class.new.key }

    it 'pushes the jid to the named queue', :freeze_time do
      described_class.notify(key, 123)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.ttl(key)).to eq(described_class::DEFAULT_TTL)
      end
    end

    it 'can be passed a custom TTL', :freeze_time do
      described_class.notify(key, 123, ttl: 5.minutes)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.ttl(key)).to eq(5.minutes.to_i)
      end
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(custom_job_waiter_ttl: false)
      end

      it 'ignores the custom TTL', :freeze_time do
        described_class.notify(key, 123, ttl: 5.minutes)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.ttl(key)).to eq(described_class::DEFAULT_TTL)
        end
      end
    end
  end

  describe '.generate_key' do
    it 'generates and return a new key' do
      key = described_class.generate_key

      expect(key).to include('gitlab:job_waiter:')
    end
  end

  describe '.delete_key' do
    let(:key) { described_class.generate_key }

    it 'deletes the key' do
      described_class.notify(key, '1')
      described_class.delete_key(key)

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.llen(key)).to eq(0)
      end
    end

    context 'when key is not a JobWaiter key' do
      let(:key) { 'foo' }

      it 'does not delete the key' do
        described_class.notify(key, '1')
        described_class.delete_key(key)

        Gitlab::Redis::SharedState.with do |redis|
          expect(redis.llen(key)).to eq(1)
        end
      end
    end
  end

  describe '#wait' do
    let(:waiter) { described_class.new(2) }

    before do
      allow_any_instance_of(described_class).to receive(:wait).and_call_original
    end

    it 'returns when all jobs have been completed' do
      described_class.notify(waiter.key, 'a')
      described_class.notify(waiter.key, 'b')

      result = nil
      expect { Timeout.timeout(1) { result = waiter.wait(2) } }.not_to raise_error

      expect(result).to contain_exactly('a', 'b')
    end

    it 'times out if not all jobs complete' do
      described_class.notify(waiter.key, 'a')

      result = nil
      expect { Timeout.timeout(2) { result = waiter.wait(1) } }.not_to raise_error

      expect(result).to contain_exactly('a')
    end

    context 'when a label is provided' do
      let(:waiter) { described_class.new(2, worker_label: 'Foo') }
      let(:started_total) { double(:started_total) }
      let(:timeouts_total) { double(:timeouts_total) }

      before do
        allow(Gitlab::Metrics).to receive(:counter)
                                    .with(described_class::STARTED_METRIC, anything)
                                    .and_return(started_total)

        allow(Gitlab::Metrics).to receive(:counter)
                                    .with(described_class::TIMEOUTS_METRIC, anything)
                                    .and_return(timeouts_total)
      end

      it 'increments just job_waiter_started_total when all jobs complete' do
        expect(started_total).to receive(:increment).with(worker: 'Foo')
        expect(timeouts_total).not_to receive(:increment)

        described_class.notify(waiter.key, 'a')
        described_class.notify(waiter.key, 'b')

        expect { Timeout.timeout(1) { waiter.wait(2) } }.not_to raise_error
      end

      it 'increments job_waiter_started_total and job_waiter_timeouts_total when it times out' do
        expect(started_total).to receive(:increment).with(worker: 'Foo')
        expect(timeouts_total).to receive(:increment).with(worker: 'Foo')

        expect { Timeout.timeout(2) { waiter.wait(1) } }.not_to raise_error
      end
    end
  end
end
