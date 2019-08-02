# frozen_string_literal: true

require 'spec_helper'

describe Namespaces::RootStatisticsWorker, '#perform' do
  let(:group) { create(:group, :with_aggregation_schedule) }

  subject(:worker) { described_class.new }

  context 'with a namespace' do
    it 'executes refresher service' do
      expect_any_instance_of(Namespaces::StatisticsRefresherService)
        .to receive(:execute)

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

        expect(Gitlab::SidekiqLogger).to receive(:error).once

        worker.perform(group.id)
      end
    end
  end

  context 'with no namespace' do
    before do
      group.destroy
    end

    it 'does not execute the refresher service' do
      expect_any_instance_of(Namespaces::StatisticsRefresherService)
        .not_to receive(:execute)

      worker.perform(group.id)
    end
  end

  context 'with a namespace with no aggregation scheduled' do
    before do
      group.aggregation_schedule.destroy
    end

    it 'does not execute the refresher service' do
      expect_any_instance_of(Namespaces::StatisticsRefresherService)
        .not_to receive(:execute)

      worker.perform(group.id)
    end
  end
end
