# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::RootStatisticsWorker, '#perform', feature_category: :source_code_management do
  let_it_be(:group) { create(:group, :with_aggregation_schedule) }

  subject(:worker) { described_class.new }

  context 'with a namespace' do
    it 'executes refresher service' do
      expect_any_instance_of(Namespaces::StatisticsRefresherService)
        .to receive(:execute).and_call_original

      worker.perform(group.id)
    end

    it 'deletes namespace aggregated schedule row' do
      worker.perform(group.id)

      expect(group.reload.aggregation_schedule).to be_nil
    end

    context 'when something goes wrong when updating' do
      before do
        allow_any_instance_of(Namespaces::StatisticsRefresherService)
          .to receive(:execute)
          .and_raise(Namespaces::StatisticsRefresherService::RefresherError, 'error')
      end

      it 'does not delete the aggregation schedule' do
        worker.perform(group.id)

        expect(group.reload.aggregation_schedule).to be_present
      end

      it 'logs the error' do
        # A Namespace::RootStatisticsWorker is scheduled when
        # a Namespace::AggregationSchedule is created, so having
        # create(:group, :with_aggregation_schedule), will execute
        # another worker
        allow_any_instance_of(Namespace::AggregationSchedule)
          .to receive(:schedule_root_storage_statistics).and_return(nil)

        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        worker.perform(group.id)
      end
    end
  end

  context 'with no namespace' do
    before do
      group.destroy!
    end

    it 'does not execute the refresher service' do
      expect_any_instance_of(Namespaces::StatisticsRefresherService)
        .not_to receive(:execute)

      worker.perform(group.id)
    end
  end

  context 'with a namespace with no aggregation scheduled' do
    before do
      group.aggregation_schedule.destroy!
    end

    it 'does not execute the refresher service' do
      expect_any_instance_of(Namespaces::StatisticsRefresherService)
        .not_to receive(:execute)

      worker.perform(group.id)
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group.id] }

    it 'deletes one aggregation schedule' do
      expect { worker.perform(*job_args) }
        .to change { Namespace::AggregationSchedule.count }.by(-1)
      expect { worker.perform(*job_args) }
        .not_to change { Namespace::AggregationSchedule.count }
    end
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once })
  end
end
