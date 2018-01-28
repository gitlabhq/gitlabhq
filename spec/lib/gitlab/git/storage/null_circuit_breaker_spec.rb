require 'spec_helper'

describe Gitlab::Git::Storage::NullCircuitBreaker do
  let(:storage) { 'default' }
  let(:hostname) { 'localhost' }
  let(:error) { nil }

  subject(:breaker) { described_class.new(storage, hostname, error: error) }

  context 'with an error' do
    let(:error) { Gitlab::Git::Storage::Misconfiguration.new('error') }

    describe '#perform' do
      it { expect { breaker.perform { 'ok' } }.to raise_error(error) }
    end

    describe '#circuit_broken?' do
      it { expect(breaker.circuit_broken?).to be_truthy }
    end

    describe '#last_failure' do
      it { Timecop.freeze { expect(breaker.last_failure).to eq(Time.now) } }
    end

    describe '#failure_count' do
      it { expect(breaker.failure_count).to eq(breaker.failure_count_threshold) }
    end

    describe '#failure_info' do
      it { expect(breaker.failure_info.no_failures?).to be_falsy }
    end
  end

  context 'not broken' do
    describe '#perform' do
      it { expect(breaker.perform { 'ok' }).to eq('ok') }
    end

    describe '#circuit_broken?' do
      it { expect(breaker.circuit_broken?).to be_falsy }
    end

    describe '#last_failure' do
      it { expect(breaker.last_failure).to be_nil }
    end

    describe '#failure_count' do
      it { expect(breaker.failure_count).to eq(0) }
    end

    describe '#failure_info' do
      it { expect(breaker.failure_info.no_failures?).to be_truthy }
    end
  end

  describe '#failure_count_threshold' do
    before do
      stub_application_setting(circuitbreaker_failure_count_threshold: 1)
    end

    it { expect(breaker.failure_count_threshold).to eq(1) }
  end

  it 'implements the CircuitBreaker interface' do
    ours = described_class.public_instance_methods
    theirs = Gitlab::Git::Storage::CircuitBreaker.public_instance_methods

    expect(theirs - ours).to be_empty
  end
end
