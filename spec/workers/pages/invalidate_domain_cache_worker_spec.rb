# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::InvalidateDomainCacheWorker do
  shared_examples 'clears caches with' do |event_class:, event_data:, caches:|
    let(:event) do
      event_class.new(data: event_data)
    end

    subject { consume_event(subscriber: described_class, event: event) }

    it_behaves_like 'subscribes to event'

    it 'clears the cache with Gitlab::Pages::CacheControl' do
      caches.each do |cache_type, cache_id|
        expect_next_instance_of(Gitlab::Pages::CacheControl, type: cache_type, id: cache_id) do |cache_control|
          expect(cache_control).to receive(:clear_cache)
        end
      end

      subject
    end
  end

  it_behaves_like 'clears caches with',
    event_class: Pages::PageDeployedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: { namespace: 3, project: 1 }

  it_behaves_like 'clears caches with',
    event_class: Pages::PageDeletedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: { namespace: 3, project: 1 }

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectDeletedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: { namespace: 3, project: 1 }
end
