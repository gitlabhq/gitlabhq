# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Findings, feature_category: :database do
  describe 'SEVERITY_ORDER' do
    it 'covers exactly the severities the web card knows about' do
      expect(described_class::SEVERITY_ORDER.keys).to eq(%w[error warning])
    end
  end

  describe '.sort' do
    it 'places errors before warnings' do
      findings = [{ severity: 'warning', code: 'a' }, { severity: 'error', code: 'b' }]

      expect(described_class.sort(findings).pluck(:code)).to eq(%w[b a])
    end

    it 'keeps the original order within a severity' do
      findings = [
        { severity: 'warning', code: 'a' },
        { severity: 'error', code: 'b' },
        { severity: 'warning', code: 'c' },
        { severity: 'error', code: 'd' }
      ]

      expect(described_class.sort(findings).pluck(:code)).to eq(%w[b d a c])
    end

    it 'places an unknown severity last' do
      findings = [{ severity: 'notice', code: 'a' }, { severity: 'warning', code: 'b' }]

      expect(described_class.sort(findings).pluck(:code)).to eq(%w[b a])
    end

    it 'returns an empty array for no findings' do
      expect(described_class.sort([])).to eq([])
    end
  end

  describe '.counts' do
    it 'tallies findings by severity' do
      findings = [{ severity: 'warning' }, { severity: 'error' }, { severity: 'warning' }]

      expect(described_class.counts(findings)).to eq({ 'warning' => 2, 'error' => 1 })
    end

    it 'returns an empty hash for no findings' do
      expect(described_class.counts([])).to eq({})
    end
  end

  describe '.worst' do
    where(:severities, :expected) do
      [
        [[], nil],
        [%w[warning], 'warning'],
        [%w[warning error warning], 'error'],
        [%w[notice], nil]
      ]
    end

    with_them do
      it { expect(described_class.worst(severities)).to eq(expected) }
    end
  end
end
