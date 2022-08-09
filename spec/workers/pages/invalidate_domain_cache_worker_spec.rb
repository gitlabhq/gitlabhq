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
      caches.each do |cache|
        expect_next_instance_of(Gitlab::Pages::CacheControl, type: cache[:type], id: cache[:id]) do |cache_control|
          expect(cache_control).to receive(:clear_cache)
        end
      end

      subject
    end
  end

  it_behaves_like 'clears caches with',
    event_class: Pages::PageDeployedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 },
      { type: :project, id: 1 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Pages::PageDeletedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 },
      { type: :project, id: 1 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectDeletedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 },
      { type: :project, id: 1 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectCreatedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 },
      { type: :project, id: 1 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectArchivedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 },
      { type: :project, id: 1 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectPathChangedEvent,
    event_data: {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3,
      old_path: 'old_path',
      new_path: 'new_path'
    },
    caches: [
      { type: :namespace, id: 3 },
      { type: :project, id: 1 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectTransferedEvent,
    event_data: {
      project_id: 1,
      old_namespace_id: 2,
      old_root_namespace_id: 3,
      new_namespace_id: 4,
      new_root_namespace_id: 5
    },
    caches: [
      { type: :project, id: 1 },
      { type: :namespace, id: 3 },
      { type: :namespace, id: 5 }
    ]

  context 'when namespace based cache keys are duplicated' do
    # de-dups namespace cache keys
    it_behaves_like 'clears caches with',
      event_class: Projects::ProjectTransferedEvent,
      event_data: {
        project_id: 1,
        old_namespace_id: 2,
        old_root_namespace_id: 5,
        new_namespace_id: 4,
        new_root_namespace_id: 5
      },
      caches: [
        { type: :project, id: 1 },
        { type: :namespace, id: 5 }
      ]
  end
end
