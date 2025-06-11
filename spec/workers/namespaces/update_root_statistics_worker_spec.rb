# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UpdateRootStatisticsWorker, feature_category: :source_code_management do
  let_it_be(:namespace) { create(:namespace) }

  let(:event) do
    Projects::ProjectDeletedEvent.new(data: { project_id: 1, namespace_id: namespace.id, root_namespace_id: 1 })
  end

  subject { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  it 'enqueues ScheduleAggregationWorker' do
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(namespace.id)

    subject
  end
end
