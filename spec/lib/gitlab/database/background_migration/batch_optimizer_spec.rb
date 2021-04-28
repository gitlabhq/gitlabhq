# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchOptimizer do
  describe '#optimize' do
    subject { described_class.new(migration, number_of_jobs: number_of_jobs).optimize! }

    let(:migration) { create(:batched_background_migration, batch_size: batch_size, sub_batch_size: 100, interval: 120) }

    let(:batch_size) { 10_000 }

    let_it_be(:number_of_jobs) { 5 }

    def mock_efficiency(eff)
      expect(migration).to receive(:smoothed_time_efficiency).with(number_of_jobs: number_of_jobs).and_return(eff)
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

    it 'with a time efficiency of 70%, it increases the batch size by 10%' do
      mock_efficiency(0.7)

      expect { subject }.to change { migration.reload.batch_size }.from(10_000).to(11_000)
    end

    it 'with a time efficiency of 110%, it decreases the batch size by 20%' do
      mock_efficiency(1.1)

      expect { subject }.to change { migration.reload.batch_size }.from(10_000).to(8_000)
    end

    context 'reaching the upper limit for the batch size' do
      let(:batch_size) { 950_000 }

      it 'caps the batch size at 10M' do
        mock_efficiency(0.7)

        expect { subject }.to change { migration.reload.batch_size }.to(1_000_000)
      end
    end

    context 'reaching the lower limit for the batch size' do
      let(:batch_size) { 1_050 }

      it 'caps the batch size at 1k' do
        mock_efficiency(1.1)

        expect { subject }.to change { migration.reload.batch_size }.to(1_000)
      end
    end
  end
end
