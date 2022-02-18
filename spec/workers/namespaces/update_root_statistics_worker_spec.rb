# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UpdateRootStatisticsWorker do
  let(:namespace_id) { 123 }

  let(:event) do
    Projects::ProjectDeletedEvent.new(data: { project_id: 1, namespace_id: namespace_id })
  end

  subject { consume_event(event) }

  def consume_event(event)
    described_class.new.perform(event.class.name, event.data)
  end

  it 'enqueues ScheduleAggregationWorker' do
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(namespace_id)

    subject
  end
end
