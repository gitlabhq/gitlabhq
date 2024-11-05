# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchOptimizer do
  describe '#optimize' do
    subject { described_class.new(migration, number_of_jobs: number_of_jobs, ema_alpha: ema_alpha).optimize! }

    let(:migration_params) { {} }
    let(:migration) do
      params = { batch_size: batch_size, sub_batch_size: 100, interval: 120 }.merge(migration_params)
      create(:batched_background_migration, params)
    end

    let(:batch_size) { 10_000 }

    let_it_be(:number_of_jobs) { 5 }
    let_it_be(:ema_alpha) { 0.4 }

    let_it_be(:target_efficiency) { described_class::TARGET_EFFICIENCY.max }

    def mock_efficiency(eff)
      expect(migration).to receive(:smoothed_time_efficiency).with(number_of_jobs: number_of_jobs, alpha: ema_alpha).and_return(eff)
    end

    it 'with unknown time efficiency, it keeps the batch size' do
      mock_efficiency(nil)

      expect { subject }.not_to change { migration.reload.batch_size }
    end

    it 'with a time efficiency of 95%, it keeps the batch size' do
      mock_efficiency(0.95)

      expect { subject }.not_to change { migration.reload.batch_size }
    end

    it 'with a time efficiency of 90%, it keeps the batch size' do
      mock_efficiency(0.9)

      expect { subject }.not_to change { migration.reload.batch_size }
    end

    it 'with a time efficiency of 85%, it increases the batch size' do
      time_efficiency = 0.85

      mock_efficiency(time_efficiency)

      new_batch_size = ((target_efficiency / time_efficiency) * batch_size).to_i

      expect { subject }.to change { migration.reload.batch_size }.from(batch_size).to(new_batch_size)
    end

    it 'with a time efficiency of 110%, it decreases the batch size' do
      time_efficiency = 1.1

      mock_efficiency(time_efficiency)

      new_batch_size = ((target_efficiency / time_efficiency) * batch_size).to_i

      expect { subject }.to change { migration.reload.batch_size }.from(batch_size).to(new_batch_size)
    end

    context 'reaching the upper limit for an increase' do
      it 'caps the batch size multiplier at 20% when increasing' do
        time_efficiency = 0.1 # this would result in a factor of 10 if not limited

        mock_efficiency(time_efficiency)

        new_batch_size = (1.2 * batch_size).to_i

        expect { subject }.to change { migration.reload.batch_size }.from(batch_size).to(new_batch_size)
      end

      it 'does not limit the decrease multiplier' do
        time_efficiency = 10

        mock_efficiency(time_efficiency)

        new_batch_size = (0.1 * batch_size).to_i

        expect { subject }.to change { migration.reload.batch_size }.from(batch_size).to(new_batch_size)
      end
    end

    context 'reaching the upper limit for the batch size' do
      let(:batch_size) { 1_950_000 }

      it 'caps the batch size at 10M' do
        mock_efficiency(0.7)

        expect { subject }.to change { migration.reload.batch_size }.to(2_000_000)
      end

      context 'when max_batch_size is set' do
        let(:max_batch_size) { 10000 }
        let(:migration_params) { { max_batch_size: max_batch_size } }

        it 'caps the batch size at max_batch_size' do
          mock_efficiency(0.7)

          expect { subject }.to change { migration.reload.batch_size }.to(max_batch_size)
        end
      end
    end

    context 'reaching the lower limit for the batch size' do
      let(:batch_size) { 1_050 }

      it 'caps the batch size at 1k' do
        mock_efficiency(1.1)

        expect { subject }.to change { migration.reload.batch_size }.to(1_000)
      end
    end

    context 'when migration max_batch_size is less than MIN_BATCH_SIZE' do
      let(:migration_params) { { max_batch_size: 900 } }

      it 'does not raise an error' do
        mock_efficiency(0.7)
        expect { subject }.not_to raise_error
      end
    end
  end
end
