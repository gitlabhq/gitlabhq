# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Transaction::Context, feature_category: :database do
  subject { described_class.new }

  let(:data) { subject.context }

  before do
    stub_const("#{described_class}::LOG_THROTTLE", 100)
  end

  describe '#set_start_time' do
    before do
      subject.set_start_time
    end

    it 'sets start_time' do
      expect(data).to have_key(:start_time)
    end
  end

  describe '#increment_savepoints' do
    before do
      2.times { subject.increment_savepoints }
    end

    it { expect(data[:savepoints]).to eq(2) }
  end

  describe '#increment_rollbacks' do
    before do
      3.times { subject.increment_rollbacks }
    end

    it { expect(data[:rollbacks]).to eq(3) }
  end

  describe '#increment_releases' do
    before do
      4.times { subject.increment_releases }
    end

    it { expect(data[:releases]).to eq(4) }
  end

  describe '#set_depth' do
    before do
      subject.set_depth(2)
    end

    it { expect(data[:depth]).to eq(2) }
  end

  describe '#track_sql' do
    before do
      subject.track_sql('SELECT 1')
      subject.track_sql('SELECT * FROM users')
    end

    it { expect(data[:queries]).to eq(['SELECT 1', 'SELECT * FROM users']) }
  end

  describe '#track_backtrace' do
    before do
      subject.track_backtrace(caller)
    end

    it { expect(data[:backtraces]).to be_a(Array) }
    it { expect(data[:backtraces]).to all(be_a(Array)) }
    it { expect(data[:backtraces].length).to eq(1) }
    it { expect(data[:backtraces][0][0]).to be_a(String) }

    it 'appends the backtrace' do
      subject.track_backtrace(caller)

      expect(data[:backtraces].length).to eq(2)
      expect(subject.backtraces).to be_a(Array)
      expect(subject.backtraces).to all(be_a(Array))
      expect(subject.backtraces[1][0]).to be_a(String)
    end
  end

  describe '#duration' do
    before do
      subject.set_start_time
    end

    it { expect(subject.duration).to be >= 0 }
  end

  shared_examples 'logs transaction data' do
    it 'logs once upon COMMIT' do
      expect(subject).to receive(:application_info).and_call_original

      2.times { subject.commit }
    end

    it 'logs once upon ROLLBACK' do
      expect(subject).to receive(:application_info).once

      2.times { subject.rollback }
    end

    it 'logs again when log throttle duration passes' do
      expect(subject).to receive(:application_info).twice.and_call_original

      2.times { subject.commit }

      data[:last_log_timestamp] -= (described_class::LOG_THROTTLE_DURATION + 1)

      subject.commit
    end

    it '#should_log? returns true' do
      expect(subject.should_log?).to be true
    end
  end

  context 'when savepoints count exceeds threshold' do
    before do
      data[:savepoints] = 1
    end

    it_behaves_like 'logs transaction data'
  end

  context 'when duration exceeds threshold' do
    before do
      subject.set_start_time

      data[:start_time] -= (described_class::LOG_DURATION_S_THRESHOLD + 1)
    end

    it_behaves_like 'logs transaction data'
  end

  context 'when there are too many external HTTP requests' do
    before do
      allow(::Gitlab::Metrics::Subscribers::ExternalHttp)
        .to receive(:request_count)
        .and_return(100)
    end

    it_behaves_like 'logs transaction data'
  end

  context 'when there are too many too long external HTTP requests' do
    before do
      allow(::Gitlab::Metrics::Subscribers::ExternalHttp)
        .to receive(:duration)
        .and_return(5.5)
    end

    it_behaves_like 'logs transaction data'
  end
end
