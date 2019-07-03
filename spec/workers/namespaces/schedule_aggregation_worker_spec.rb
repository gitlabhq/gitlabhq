# frozen_string_literal: true

require 'spec_helper'

describe Namespaces::ScheduleAggregationWorker, '#perform' do
  let(:group) { create(:group) }

  subject(:worker) { described_class.new }

  context 'when group is the root ancestor' do
    context 'when aggregation schedule exists' do
      it 'does not create a new one' do
        Namespace::AggregationSchedule.safe_find_or_create_by!(namespace_id: group.id)

        expect do
          worker.perform(group.id)
        end.not_to change(Namespace::AggregationSchedule, :count)
      end
    end

    context 'when update_statistics_namespace is off' do
      it 'does not create a new one' do
        stub_feature_flags(update_statistics_namespace: false, namespace: group)

        expect do
          worker.perform(group.id)
        end.not_to change(Namespace::AggregationSchedule, :count)
      end
    end

    context 'when aggregation schedule does not exist' do
      it 'creates one' do
        allow_any_instance_of(Namespace::AggregationSchedule)
          .to receive(:schedule_root_storage_statistics).and_return(nil)

        expect do
          worker.perform(group.id)
        end.to change(Namespace::AggregationSchedule, :count).by(1)

        expect(group.aggregation_schedule).to be_present
      end
    end
  end

  context 'when group is not the root ancestor' do
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }

    it 'creates an aggregation schedule for the root' do
      allow_any_instance_of(Namespace::AggregationSchedule)
        .to receive(:schedule_root_storage_statistics).and_return(nil)

      worker.perform(group.id)

      expect(parent_group.aggregation_schedule).to be_present
    end
  end

  context 'when namespace does not exist' do
    it 'logs the error' do
      expect(Gitlab::SidekiqLogger).to receive(:error).once

      worker.perform(12345)
    end
  end
end
