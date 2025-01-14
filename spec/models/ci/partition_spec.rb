# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partition, feature_category: :ci_scaling do
  let_it_be_with_reload(:ci_partition) { create(:ci_partition) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:id) }
    it { is_expected.to validate_presence_of(:status) }

    it 'is valid' do
      expect(ci_partition).to be_valid
    end

    context 'when status is current' do
      before do
        ci_partition.update!(status: described_class.statuses[:current])
      end

      it { is_expected.to validate_uniqueness_of(:status) }
    end
  end

  describe '.create_next!' do
    subject(:next_ci_partition) { described_class.create_next! }

    let(:ci_last_partition) { described_class.last }

    it 'creates a new record', :aggregate_failures do
      expect { next_ci_partition }.to change { Ci::Partition.count }.by(1)
      expect(ci_last_partition.id).to eq(ci_partition.id + 1)
      expect(ci_last_partition.status).to eq(described_class.statuses[:preparing])
    end
  end

  describe '.statuses' do
    subject(:statuses) { described_class.statuses }

    it 'returns the statuses' do
      expect(statuses).to eq({
        preparing: 0,
        ready: 1,
        current: 2,
        active: 3
      })
    end
  end

  describe 'scopes' do
    describe '.current' do
      subject(:current) { described_class.current }

      context 'when no ci_partition is marked as current' do
        it { is_expected.to be_nil }
      end

      context 'when a given ci_partition is marked as current' do
        before do
          ci_partition.update!(status: described_class.statuses[:current])
        end

        it 'returns the current record' do
          is_expected.to eq(ci_partition)
        end
      end
    end

    describe '.id_after' do
      subject(:id_after) { described_class.id_after(ci_partition.id) }

      let(:ci_next_partition) { create(:ci_partition) }

      it 'returns ci_partitions above given id' do
        expect(id_after).to match_array(ci_next_partition)
      end
    end

    describe '.next_available' do
      subject(:next_available) { described_class.next_available(ci_partition.id) }

      let!(:next_ci_partition) { create(:ci_partition, :ready) }

      context 'when one partition is ready' do
        it { is_expected.to eq(next_ci_partition) }
      end

      context 'when multiple partitions are ready' do
        before do
          create_list(:ci_partition, 2, :ready)
        end

        it 'returns the first next partition available' do
          expect(next_available).to eq(next_ci_partition)
        end
      end
    end

    describe '.provisioning' do
      subject(:provisioning) { described_class.provisioning(ci_partition.id) }

      let!(:next_ci_partition) { create(:ci_partition) }

      context 'when one partition is preparing' do
        it { is_expected.to eq(next_ci_partition) }
      end

      context 'when multiple partitions are preparing' do
        before do
          create_list(:ci_partition, 2)
        end

        it 'returns the first ci_partition with status preparing' do
          expect(provisioning).to eq(next_ci_partition)
        end
      end
    end
  end

  describe 'state machine' do
    context 'when transitioning from prepare to ready' do
      before do
        ci_partition.ready!
      end

      it 'status is ready' do
        expect(ci_partition).to be_ready
      end
    end

    context 'when transitioning from current to active' do
      let!(:next_ci_partition) { create(:ci_partition, :ready) }

      before do
        ci_partition.update!(status: described_class.statuses[:current])
        next_ci_partition.switch_writes!
      end

      it 'updates statuses for current and next partition' do
        expect(ci_partition.reload).to be_active
        expect(next_ci_partition.reload).to be_current
      end
    end
  end

  describe '#switch_writes!' do
    let_it_be_with_reload(:ready_partition) { create(:ci_partition, :ready) }
    let_it_be_with_reload(:active_partition) { create(:ci_partition, :active) }
    let_it_be_with_reload(:current_partition) { create(:ci_partition, :current) }

    it 'switches from ready to current' do
      expect { ready_partition.switch_writes! }
        .to change { described_class.current }
        .from(current_partition).to(ready_partition)

      expect(current_partition.reload).to be_active
      expect(ready_partition.reload).to be_current
    end

    it 'switches from active to current' do
      expect { active_partition.switch_writes! }
        .to change { described_class.current }
        .from(current_partition).to(active_partition)

      expect(current_partition.reload).to be_active
      expect(active_partition.reload).to be_current
    end
  end

  describe '#above_threshold?' do
    subject(:above_threshold) { ci_partition.above_threshold?(threshold) }

    context 'when one of the partition is above the threshold' do
      let(:threshold) { 1.byte }

      it { is_expected.to eq(true) }
    end

    context 'when all partitions are below the threshold' do
      let(:threshold) { 1.megabyte }

      it { is_expected.to eq(false) }
    end
  end

  describe '#all_partitions_exist?' do
    subject(:all_partitions_exist) { ci_partition.all_partitions_exist? }

    context 'when all partitions exist' do
      it { is_expected.to eq(true) }
    end

    context 'when database partitions does not exist for ci_partition record' do
      let(:ci_partition) { create(:ci_partition, id: non_existing_record_id) }

      it { is_expected.to eq(false) }
    end
  end
end
