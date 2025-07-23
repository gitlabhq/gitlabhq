# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::Throttling::Strategy, feature_category: :scalability do
  using RSpec::Parameterized::TableSyntax

  describe '.SoftThrottle' do
    where(:input, :expected_output) do
      100 | 80
      5 | 4
      4 | 4
    end

    with_them do
      it 'calculates the concurrency limit correctly' do
        expect(described_class::SoftThrottle.concurrency_operator.call(input)).to eq(expected_output)
      end
    end
  end

  describe '.HardThrottle' do
    where(:input, :expected_output) do
      100 | 50
      50 | 25
      25 | 13
      13 | 7
      7 | 4
      4 | 2
      2 | 1
      1 | 1
    end

    with_them do
      it 'calculates the concurrency limit correctly' do
        expect(described_class::HardThrottle.concurrency_operator.call(input)).to eq(expected_output)
      end
    end
  end

  describe '.GradualRecovery' do
    where(:input, :expected_output) do
      1 | 2
      2 | 3
      100 | 110
    end

    with_them do
      it 'calculates the concurrency limit correctly' do
        expect(described_class::GradualRecovery.concurrency_operator.call(input)).to eq(expected_output)
      end
    end
  end

  describe '.None' do
    it 'has a nil concurrency_operator' do
      expect(described_class::None.concurrency_operator).to be_nil
    end
  end
end
