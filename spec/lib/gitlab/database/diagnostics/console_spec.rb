# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Console, feature_category: :database do
  describe '.summarize' do
    where(:counts, :expected) do
      [
        [{}, nil],
        [{ 'error' => 1 }, '1 error'],
        [{ 'warning' => 2 }, '2 warnings'],
        [{ 'warning' => 2, 'error' => 1 }, '1 error, 2 warnings'],
        [{ 'notice' => 1, 'error' => 1 }, '1 error, 1 notice']
      ]
    end

    with_them do
      it { expect(described_class.summarize(counts)).to eq(expected) }
    end
  end

  describe '.merge_counts' do
    it 'sums each severity across every hash' do
      merged = described_class.merge_counts([{ 'error' => 1, 'warning' => 1 }, { 'warning' => 2 }])

      expect(merged).to eq({ 'error' => 1, 'warning' => 3 })
    end

    it 'returns an empty hash for no input' do
      expect(described_class.merge_counts([])).to eq({})
    end
  end
end
