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
end
