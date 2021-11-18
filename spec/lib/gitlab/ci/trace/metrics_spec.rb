# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Trace::Metrics, :prometheus do
  describe '#increment_trace_bytes' do
    context 'when incrementing by more than one' do
      it 'increments a single counter' do
        subject.increment_trace_bytes(10)
        subject.increment_trace_bytes(20)
        subject.increment_trace_bytes(30)

        expect(described_class.trace_bytes.get).to eq 60
        expect(described_class.trace_bytes.values.count).to eq 1
      end
    end
  end

  describe '#increment_error_counter' do
    context 'when the error reason is known' do
      it 'increments the counter' do
        subject.increment_error_counter(error_reason: :chunks_invalid_size)
        subject.increment_error_counter(error_reason: :chunks_invalid_checksum)
        subject.increment_error_counter(error_reason: :archive_invalid_checksum)

        expect(described_class.trace_errors_counter.get(error_reason: :chunks_invalid_size)).to eq 1
        expect(described_class.trace_errors_counter.get(error_reason: :chunks_invalid_checksum)).to eq 1
        expect(described_class.trace_errors_counter.get(error_reason: :archive_invalid_checksum)).to eq 1

        expect(described_class.trace_errors_counter.values.count).to eq 3
      end
    end

    context 'when the error reason is unknown' do
      it 'raises an exception' do
        expect { subject.increment_error_counter(error_reason: :invalid_type) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
