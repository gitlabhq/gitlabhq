# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies do
  describe '.for' do
    it 'returns the right class for `until_executing`' do
      expect(described_class.for(:until_executing)).to eq(described_class::UntilExecuting)
    end

    it 'returns the right class for `until_executed`' do
      expect(described_class.for(:until_executed)).to eq(described_class::UntilExecuted)
    end

    it 'returns the right class for `none`' do
      expect(described_class.for(:none)).to eq(described_class::None)
    end

    it 'raises an UnknownStrategyError when passing an unknown key' do
      expect { described_class.for(:unknown) }.to raise_error(described_class::UnknownStrategyError)
    end
  end
end
