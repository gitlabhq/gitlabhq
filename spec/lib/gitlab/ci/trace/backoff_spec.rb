# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace::Backoff do
  using RSpec::Parameterized::TableSyntax

  subject(:backoff) { described_class.new(archival_attempts) }

  it 'keeps the MAX_ATTEMPTS limit in sync' do
    expect(Ci::BuildTraceMetadata::MAX_ATTEMPTS).to eq(5)
  end

  it 'keeps the Redis TTL limit in sync' do
    expect(Ci::BuildTraceChunks::RedisBase::CHUNK_REDIS_TTL).to eq(7.days)
  end

  describe '#value' do
    where(:archival_attempts, :result) do
      1  | 9.6
      2  | 19.2
      3  | 28.8
      4  | 38.4
      5  | 48.0
    end

    with_them do
      subject { backoff.value }

      it { is_expected.to eq(result.hours) }
    end
  end

  describe '#value_with_jitter' do
    where(:archival_attempts, :min_value, :max_value) do
      1 |  9.6 | 13.6
      2 | 19.2 | 23.2
      3 | 28.8 | 32.8
      4 | 38.4 | 42.4
      5 | 48.0 | 52.0
    end

    with_them do
      subject { backoff.value_with_jitter }

      it { is_expected.to be_in(min_value.hours..max_value.hours) }
    end
  end

  it 'all retries are happening under the 7 days limit' do
    backoff_total = 1.upto(Ci::BuildTraceMetadata::MAX_ATTEMPTS).sum do |attempt|
      backoff = described_class.new(attempt)
      expect(backoff).to receive(:rand)
        .with(described_class::MAX_JITTER_VALUE)
        .and_return(described_class::MAX_JITTER_VALUE)

      backoff.value_with_jitter
    end

    expect(backoff_total).to be < Ci::BuildTraceChunks::RedisBase::CHUNK_REDIS_TTL
  end
end
