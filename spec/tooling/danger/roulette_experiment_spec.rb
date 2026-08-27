# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/danger/roulette_experiment'

RSpec.describe Tooling::Danger::RouletteExperiment, feature_category: :tooling do
  describe '.hide_reviewer_column?' do
    it 'is deterministic for the same MR iid' do
      result = described_class.hide_reviewer_column?(1234)

      3.times { expect(described_class.hide_reviewer_column?(1234)).to eq(result) }
    end

    it 'splits MRs into both arms across a range of iids' do
      results = (1..2000).map { |iid| described_class.hide_reviewer_column?(iid) }

      expect(results).to include(true).and include(false)
    end

    context 'with a default hidden percent of 50%' do
      it 'hides for roughly half of a large sample of iids' do
        hidden_count = (1..5000).count { |iid| described_class.hide_reviewer_column?(iid) }

        expect(hidden_count / 5000.0).to be_within(0.05).of(0.5)
      end
    end

    context 'when ROULETTE_HIDE_REVIEWER_COLUMN_PERCENT is set' do
      it 'hides for nobody when set to 0' do
        stub_env('ROULETTE_HIDE_REVIEWER_COLUMN_PERCENT', '0')

        expect((1..500).map { |iid| described_class.hide_reviewer_column?(iid) }).to all(be false)
      end

      it 'hides for everybody when set to 100' do
        stub_env('ROULETTE_HIDE_REVIEWER_COLUMN_PERCENT', '100')

        expect((1..500).map { |iid| described_class.hide_reviewer_column?(iid) }).to all(be true)
      end

      it 'lands in the expected band for an intermediate percentage' do
        stub_env('ROULETTE_HIDE_REVIEWER_COLUMN_PERCENT', '25')

        hidden_count = (1..5000).count { |iid| described_class.hide_reviewer_column?(iid) }

        expect(hidden_count / 5000.0).to be_within(0.05).of(0.25)
      end

      it 'raises for a non-numeric value' do
        stub_env('ROULETTE_HIDE_REVIEWER_COLUMN_PERCENT', 'not-a-number')

        expect { described_class.hide_reviewer_column?(1) }.to raise_error(ArgumentError)
      end
    end
  end
end
