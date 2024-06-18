# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitions::SyncService, feature_category: :ci_scaling do
  let_it_be_with_reload(:ci_partition) { create(:ci_partition, :current) }
  let_it_be_with_reload(:next_ci_partition) { create(:ci_partition) }
  let(:service) { described_class.new(ci_partition) }
  let(:current_status) { Ci::Partition.statuses[:current] }
  let(:preparing_status) { Ci::Partition.statuses[:preparing] }
  let(:active_status) { Ci::Partition.statuses[:active] }
  let(:ready_status) { Ci::Partition.statuses[:ready] }

  describe '.execute' do
    subject(:execute_service) { service.execute }

    shared_examples 'ci_partitions not updated' do
      it 'does not update ci_partition to ready', :aggregate_failures do
        expect { execute_service }
          .to not_change { ci_partition.reload.status }
          .and not_change { next_ci_partition.reload.status }
      end
    end

    context 'when ci_partitioning_automation is disabled' do
      before do
        stub_feature_flags(ci_partitioning_automation: false)
      end

      it_behaves_like 'ci_partitions not updated'
    end

    context 'when ci_partition is nil' do
      let(:ci_partition) { nil }

      it 'does not perform any action' do
        expect(service).not_to receive(:sync_partitions_statuses)
        expect(service).not_to receive(:write_to_next_partition)

        execute_service
      end
    end

    context 'when all conditions are satisfied' do
      before do
        allow(service).to receive(:above_threshold?).and_return(true)
        allow_next_found_instance_of(Ci::Partition) do |partition|
          allow(partition).to receive(:all_partitions_exist?).and_return(true)
        end
      end

      it 'updates ci_partitions statuses', :aggregate_failures do
        expect { execute_service }
          .to change { ci_partition.reload.status }.from(current_status).to(active_status)
          .and change { next_ci_partition.reload.status }.from(preparing_status).to(current_status)
      end
    end

    context 'when database_partitions are not above the threshold' do
      before do
        allow_next_found_instance_of(Ci::Partition) do |partition|
          allow(partition).to receive(:all_partitions_exist?).and_return(true)
        end
      end

      it 'updates next ci_partitions to status ready' do
        expect { execute_service }.to change { next_ci_partition.reload.status }.from(preparing_status).to(ready_status)
      end
    end

    context 'when next_partition is not ready' do
      before do
        allow_next_found_instance_of(Ci::Partition) do |partition|
          allow(partition).to receive(:all_partitions_exist?).and_return(false)
        end
      end

      it 'does not update ci_partitions statuses', :aggregate_failures do
        expect { execute_service }
         .to not_change { ci_partition.reload.status }
         .and not_change { next_ci_partition.reload.status }
      end
    end
  end
end
