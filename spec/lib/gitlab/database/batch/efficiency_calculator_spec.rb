# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Batch::EfficiencyCalculator, feature_category: :database do
  let(:batch_size) { 10_000 }
  let(:record) do
    instance_double(Gitlab::Database::BackgroundOperation::Worker, batch_size: batch_size, max_batch_size: 50_000)
  end

  let(:calculator) { described_class.new(record: record) }

  describe '#optimized_batch_size' do
    subject(:optimized_size) { calculator.optimized_batch_size }

    context 'when efficiency is low' do
      before do
        allow(calculator).to receive(:smoothed_time_efficiency).and_return(0.7)
      end

      it 'returns larger batch size' do
        # With efficiency 0.7: should increase batch size
        # Exact calculation depends on Optimizer implementation
        # Example: multiplier = 0.95/0.7 = 1.357, capped at 1.2
        # New size = 10,000 * 1.2 = 12,000
        expect(optimized_size).to eq(12_000)
      end
    end

    context 'when efficiency is high' do
      before do
        allow(calculator).to receive(:smoothed_time_efficiency).and_return(1.5)
      end

      it 'returns smaller batch size' do
        # With efficiency 1.5: should decrease batch size
        # Example: multiplier = 0.95/1.5 = 0.633
        # New size = 10,000 * 0.633 = 6,333
        expect(optimized_size).to eq(6_333)
      end
    end

    context 'when efficiency is nil' do
      before do
        allow(calculator).to receive(:smoothed_time_efficiency).and_return(nil)
      end

      it 'returns current batch size unchanged' do
        expect(optimized_size).to eq(batch_size)
      end
    end
  end

  describe '#should_optimize?' do
    subject(:should_optimize) { calculator.should_optimize? }

    context 'when efficiency is nil' do
      before do
        allow(calculator).to receive(:smoothed_time_efficiency).and_return(nil)
      end

      it 'returns false' do
        expect(should_optimize).to be_falsey
      end
    end

    context 'when efficiency is low' do
      before do
        allow(calculator).to receive(:smoothed_time_efficiency).and_return(0.7)
      end

      it 'returns true' do
        expect(should_optimize).to be_truthy
      end
    end

    context 'when efficiency is high' do
      before do
        allow(calculator).to receive(:smoothed_time_efficiency).and_return(1.5)
      end

      it 'returns true' do
        expect(should_optimize).to be_truthy
      end
    end
  end
end
