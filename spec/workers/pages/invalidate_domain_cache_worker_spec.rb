# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::InvalidateDomainCacheWorker do
  let(:event) do
    Pages::PageDeployedEvent.new(data: {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3
    })
  end

  subject { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  it 'enqueues ScheduleAggregationWorker' do
    expect_next_instance_of(Gitlab::Pages::CacheControl, type: :project, id: 1) do |cache_control|
      expect(cache_control).to receive(:clear_cache)
    end

    expect_next_instance_of(Gitlab::Pages::CacheControl, type: :namespace, id: 3) do |cache_control|
      expect(cache_control).to receive(:clear_cache)
    end

    subject
  end
end
