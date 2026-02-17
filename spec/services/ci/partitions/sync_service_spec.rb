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

    shared_examples 'ci_partition & next_ci_partition not updated' do
      it 'does not update ci_partition status', :aggregate_failures do
        expect { execute_service }
          .to not_change { ci_partition.reload.status }.from(current_status)
          .and not_change { next_ci_partition.reload.status }.from(preparing_status)
      end
    end

    shared_examples 'next_ci_partition is ready, but ci_partition not updated' do
      it 'updates next_ci_partition status', :aggregate_failures do
        expect { execute_service }
          .to not_change { ci_partition.reload.status }.from(current_status)
          .and change { next_ci_partition.reload.status }.from(preparing_status).to(ready_status)
      end
    end

    context 'when ci_partition is nil' do
      let(:ci_partition) { nil }

      it 'does not perform any action' do
        expect(service).not_to receive(:sync_partitions_statuses)
        expect(service).not_to receive(:write_to_next_partition)

        execute_service
      end
    end

    context 'for size-based partition sync' do
      before do
        stub_feature_flags(ci_time_based_partitioning: false)
      end

      context 'when all conditions are satisfied' do
        before do
          allow_next_found_instance_of(Ci::Partition) do |partition|
            allow(partition).to receive(:all_partitions_exist?).and_return(true)
          end
          allow(ci_partition).to receive(:exceed_time_window?).and_return(true)
        end

        it 'updates ci_partitions statuses', :aggregate_failures do
          expect { execute_service }
            .to change { ci_partition.reload.status }.from(current_status).to(active_status)
            .and change { next_ci_partition.reload.status }.from(preparing_status).to(current_status)
        end

        it 'logs the strategy' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Running CI partition sync service to switch write to the next one',
              strategy: 'size',
              current_partition_id: ci_partition.id,
              next_partition_id: next_ci_partition.id
            )
          )
          execute_service
        end
      end

      context 'when database_partitions are not above the threshold' do
        before do
          allow_next_found_instance_of(Ci::Partition) do |partition|
            allow(partition).to receive(:all_partitions_exist?).and_return(true)
          end
        end

        it 'updates next ci_partitions to status ready' do
          expect { execute_service }.to change {
            next_ci_partition.reload.status
          }.from(preparing_status).to(ready_status)
        end
      end

      context 'when next_partition is not ready' do
        before do
          allow_next_found_instance_of(Ci::Partition) do |partition|
            allow(partition).to receive(:all_partitions_exist?).and_return(false)
          end
        end

        it_behaves_like 'ci_partition & next_ci_partition not updated'
      end
    end

    context 'for time-based partition creation', time_travel_to: '2026-01-31' do
      before do
        stub_application_setting(ci_partitions_in_seconds_limit: ChronicDuration.parse('1 month'))
        allow_next_found_instance_of(Ci::Partition) do |partition|
          allow(partition).to receive(:all_partitions_exist?).and_return(true)
        end
      end

      context 'when time window has elapsed' do
        before do
          ci_partition.update!(current_from: 2.months.ago)
        end

        it 'updates ci_partitions statuses' do
          expect { execute_service }
            .to change { ci_partition.reload.status }.from(current_status).to(active_status)
            .and change { next_ci_partition.reload.status }.from(preparing_status).to(current_status)
        end

        it 'logs the strategy' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Running CI partition sync service to switch write to the next one',
              strategy: 'time',
              current_partition_id: ci_partition.id,
              next_partition_id: next_ci_partition.id
            )
          )
          execute_service
        end

        context 'when ci_time_based_partitioning feature flag is disabled' do
          before do
            stub_feature_flags(ci_time_based_partitioning: false)
          end

          it_behaves_like 'next_ci_partition is ready, but ci_partition not updated'
        end
      end

      context 'when time window has not elapsed' do
        before do
          ci_partition.update!(current_from: 1.week.ago)
        end

        it_behaves_like 'next_ci_partition is ready, but ci_partition not updated'

        context 'when ci_time_based_partitioning feature flag is disabled' do
          before do
            stub_feature_flags(ci_time_based_partitioning: false)
          end

          it_behaves_like 'next_ci_partition is ready, but ci_partition not updated'
        end
      end

      context 'when next partition is not ready' do
        before do
          allow_next_found_instance_of(Ci::Partition) do |partition|
            allow(partition).to receive(:all_partitions_exist?).and_return(false)
          end
        end

        it_behaves_like 'ci_partition & next_ci_partition not updated'

        context 'when ci_time_based_partitioning feature flag is disabled' do
          before do
            stub_feature_flags(ci_time_based_partitioning: false)
          end

          it_behaves_like 'ci_partition & next_ci_partition not updated'
        end
      end
    end
  end
end
