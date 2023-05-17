# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ScheduleAggregationWorker, '#perform', :clean_gitlab_redis_shared_state, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }

  subject(:worker) { described_class.new }

  context 'when group is the root ancestor' do
    context 'when aggregation schedule exists' do
      it 'does not create a new one' do
        stub_aggregation_schedule_statistics

        Namespace::AggregationSchedule.safe_find_or_create_by!(namespace_id: group.id)

        expect do
          worker.perform(group.id)
        end.not_to change { Namespace::AggregationSchedule.count }
      end
    end

    context 'when aggregation schedule does not exist' do
      it 'creates one' do
        stub_aggregation_schedule_statistics

        expect do
          worker.perform(group.id)
        end.to change { Namespace::AggregationSchedule.count }.by(1)

        expect(group.aggregation_schedule).to be_present
      end
    end
  end

  context 'when group is not the root ancestor' do
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }

    it 'creates an aggregation schedule for the root' do
      stub_aggregation_schedule_statistics

      worker.perform(group.id)

      expect(parent_group.aggregation_schedule).to be_present
    end
  end

  context 'when namespace does not exist' do
    it 'logs the error' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).once

      worker.perform(non_existing_record_id)
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group.id] }

    it 'creates a single aggregation schedule' do
      expect { worker.perform(*job_args) }
        .to change { Namespace::AggregationSchedule.count }.by(1)
      expect { worker.perform(*job_args) }
        .not_to change { Namespace::AggregationSchedule.count }
    end
  end

  def stub_aggregation_schedule_statistics
    # Namespace::Aggregations are deleted by
    # Namespace::AggregationSchedule::schedule_root_storage_statistics,
    # which is executed async. Stubing the service so instances are not deleted
    # while still running the specs.
    expect_next_instance_of(Namespace::AggregationSchedule) do |aggregation_schedule|
      expect(aggregation_schedule)
        .to receive(:schedule_root_storage_statistics)
    end
  end
end
