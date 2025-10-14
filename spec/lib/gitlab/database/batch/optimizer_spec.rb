# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Batch::Optimizer, feature_category: :database do
  using RSpec::Parameterized::TableSyntax

  let(:current_batch_size) { 10_000 }
  let(:max_batch_size) { nil }
  let(:time_efficiency) { 0.85 }
  let(:optimizer) do
    described_class.new(
      current_batch_size: current_batch_size,
      max_batch_size: max_batch_size,
      time_efficiency: time_efficiency
    )
  end

  describe '#should_optimize?' do
    subject { optimizer.should_optimize? }

    where(:time_efficiency_value, :should_optimize) do
      0.85 | true
      0.90 | false
      0.95 | false
      0.92 | false
      1.1  | true
      nil  | false
      0    | false
    end

    with_them do
      let(:time_efficiency) { time_efficiency_value }

      it { is_expected.to be should_optimize }
    end
  end

  describe '#optimized_batch_size' do
    subject(:new_batch_size) { optimizer.optimized_batch_size }

    let(:target_efficiency) { described_class::TARGET_EFFICIENCY.max }

    context 'when efficiency is below target' do
      let(:time_efficiency) { 0.85 }

      it 'increases batch size proportionally' do
        expected_size = ((target_efficiency / time_efficiency) * current_batch_size).to_i
        expect(new_batch_size).to eq(expected_size)
      end
    end

    context 'when efficiency is above target' do
      let(:time_efficiency) { 1.1 }

      it 'decreases batch size proportionally' do
        expected_size = ((target_efficiency / time_efficiency) * current_batch_size).to_i
        expect(new_batch_size).to eq(expected_size)
      end
    end

    context 'when multiplier would exceed MAX_MULTIPLIER' do
      let(:time_efficiency) { 0.1 } # Would result in 9.5x multiplier

      it 'caps the increase at MAX_MULTIPLIER (20%)' do
        expected_size = (current_batch_size * described_class::MAX_MULTIPLIER).to_i
        expect(new_batch_size).to eq(expected_size)
      end
    end

    context 'when result would exceed MAX_BATCH_SIZE' do
      let(:current_batch_size) { 1_950_000 }
      let(:time_efficiency) { 0.7 }

      it 'caps at MAX_BATCH_SIZE' do
        expect(new_batch_size).to eq(described_class::MAX_BATCH_SIZE)
      end
    end

    context 'when result would go below MIN_BATCH_SIZE' do
      let(:current_batch_size) { 1_050 }
      let(:time_efficiency) { 1.5 }

      it 'caps at MIN_BATCH_SIZE' do
        expect(new_batch_size).to eq(described_class::MIN_BATCH_SIZE)
      end
    end

    context 'with custom max_batch_size' do
      context 'when max_batch_size is between MIN and MAX' do
        let(:max_batch_size) { 15_000 }
        let(:time_efficiency) { 0.5 } # Would double the batch size without MAX_MULTIPLIER

        it 'is limited by MAX_MULTIPLIER before max_batch_size' do
          # Multiplier would be 1.9 (0.95/0.5) but capped at 1.2
          expected_size = (current_batch_size * described_class::MAX_MULTIPLIER).to_i
          expect(new_batch_size).to eq(expected_size)
        end
      end

      context 'when calculated size would exceed max_batch_size' do
        let(:max_batch_size) { 11_000 }
        let(:time_efficiency) { 0.85 } # Would increase to ~11,176

        it 'respects the custom maximum' do
          expect(new_batch_size).to eq(max_batch_size)
        end
      end

      context 'when max_batch_size is less than MIN_BATCH_SIZE' do
        let(:max_batch_size) { 500 }
        let(:current_batch_size) { 600 }
        let(:time_efficiency) { 1.5 } # Would decrease batch size

        it 'uses max_batch_size as the lower limit' do
          expect(new_batch_size).to eq(max_batch_size)
        end
      end

      context 'when current size already exceeds max_batch_size' do
        let(:current_batch_size) { 20_000 }
        let(:max_batch_size) { 15_000 }
        let(:time_efficiency) { 0.85 } # Would increase

        it 'cannot exceed the custom maximum' do
          expect(new_batch_size).to eq(max_batch_size)
        end
      end
    end

    context 'with edge cases' do
      context 'with very high efficiency requiring large decrease' do
        let(:time_efficiency) { 10 }

        it 'decreases but respects MIN_BATCH_SIZE' do
          # Would be 950 without limit, but capped at MIN_BATCH_SIZE
          expect(new_batch_size).to eq(described_class::MIN_BATCH_SIZE)
        end
      end

      context 'with efficiency very close to target' do
        let(:time_efficiency) { 0.96 } # Just above target range

        it 'still calculates the adjustment' do
          expected_size = ((target_efficiency / time_efficiency) * current_batch_size).to_i
          expect(new_batch_size).to eq(expected_size)
        end
      end
    end
  end

  describe 'constants' do
    it 'defines expected constants with correct values' do
      expect(described_class::TARGET_EFFICIENCY).to eq(0.9..0.95)
      expect(described_class::MIN_BATCH_SIZE).to eq(1_000)
      expect(described_class::MAX_BATCH_SIZE).to eq(2_000_000)
      expect(described_class::MAX_MULTIPLIER).to eq(1.2)
    end
  end

  describe 'initialization' do
    it 'allows nil max_batch_size' do
      optimizer = described_class.new(
        current_batch_size: 5000,
        time_efficiency: 0.8
      )

      expect(optimizer.max_batch_size).to be_nil
    end

    it 'allows nil time_efficiency' do
      optimizer = described_class.new(
        current_batch_size: 5000,
        max_batch_size: 10000
      )

      expect(optimizer.time_efficiency).to be_nil
    end
  end
end
