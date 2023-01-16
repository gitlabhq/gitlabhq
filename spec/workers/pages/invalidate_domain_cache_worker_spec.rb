# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::InvalidateDomainCacheWorker, feature_category: :pages do
  shared_examples 'clears caches with' do |event_class:, event_data:, caches:|
    include AfterNextHelpers

    let(:event) { event_class.new(data: event_data) }

    subject { consume_event(subscriber: described_class, event: event) }

    it_behaves_like 'subscribes to event'

    it 'clears the cache with Gitlab::Pages::CacheControl' do
      caches.each do |cache|
        expect_next(Gitlab::Pages::CacheControl, type: cache[:type], id: cache[:id])
          .to receive(:clear_cache)
      end

      subject
    end
  end

  context 'when a project have multiple domains' do
    include AfterNextHelpers

    let_it_be(:project) { create(:project) }
    let_it_be(:pages_domain) { create(:pages_domain, project: project) }
    let_it_be(:pages_domain2) { create(:pages_domain, project: project) }

    let(:event) do
      Pages::PageDeployedEvent.new(
        data: {
          project_id: project.id,
          namespace_id: project.namespace_id,
          root_namespace_id: project.root_ancestor.id
        }
      )
    end

    subject { consume_event(subscriber: described_class, event: event) }

    it 'clears the cache with Gitlab::Pages::CacheControl' do
      expect_next(Gitlab::Pages::CacheControl, type: :namespace, id: project.namespace_id)
        .to receive(:clear_cache)
      expect_next(Gitlab::Pages::CacheControl, type: :domain, id: pages_domain.id)
        .to receive(:clear_cache)
      expect_next(Gitlab::Pages::CacheControl, type: :domain, id: pages_domain2.id)
        .to receive(:clear_cache)

      subject
    end
  end

  it_behaves_like 'clears caches with',
    event_class: Pages::PageDeployedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Pages::PageDeletedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectDeletedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectCreatedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Projects::ProjectArchivedEvent,
    event_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    caches: [
      { type: :namespace, id: 3 }
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
      { type: :namespace, id: 3 }
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
      { type: :namespace, id: 3 },
      { type: :namespace, id: 5 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Groups::GroupTransferedEvent,
    event_data: {
      group_id: 1,
      old_root_namespace_id: 3,
      new_root_namespace_id: 5
    },
    caches: [
      { type: :namespace, id: 3 },
      { type: :namespace, id: 5 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Groups::GroupPathChangedEvent,
    event_data: {
      group_id: 1,
      root_namespace_id: 2,
      old_path: 'old_path',
      new_path: 'new_path'
    },
    caches: [
      { type: :namespace, id: 2 }
    ]

  it_behaves_like 'clears caches with',
    event_class: Groups::GroupDeletedEvent,
    event_data: {
      group_id: 1,
      root_namespace_id: 3
    },
    caches: [
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: PagesDomains::PagesDomainDeletedEvent,
    event_data: {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3,
      domain_id: 4,
      domain: 'somedomain.com'
    },
    caches: [
      { type: :domain, id: 4 },
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: PagesDomains::PagesDomainUpdatedEvent,
    event_data: {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3,
      domain_id: 4,
      domain: 'somedomain.com'
    },
    caches: [
      { type: :domain, id: 4 },
      { type: :namespace, id: 3 }
    ]

  it_behaves_like 'clears caches with',
    event_class: PagesDomains::PagesDomainCreatedEvent,
    event_data: {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3,
      domain_id: 4,
      domain: 'somedomain.com'
    },
    caches: [
      { type: :domain, id: 4 },
      { type: :namespace, id: 3 }
    ]

  context 'when project attributes change' do
    Projects::ProjectAttributesChangedEvent::PAGES_RELATED_ATTRIBUTES.each do |attribute|
      it_behaves_like 'clears caches with',
        event_class: Projects::ProjectAttributesChangedEvent,
        event_data: {
          project_id: 1,
          namespace_id: 2,
          root_namespace_id: 3,
          domain_id: 4,
          attributes: [attribute]
        },
        caches: [
          { type: :domain, id: 4 },
          { type: :namespace, id: 3 }
        ]
    end

    it_behaves_like 'ignores the published event' do
      let(:event) do
        Projects::ProjectAttributesChangedEvent.new(
          data: {
            project_id: 1,
            namespace_id: 2,
            root_namespace_id: 3,
            attributes: ['unknown']
          }
        )
      end
    end
  end

  context 'when project features change' do
    it_behaves_like 'clears caches with',
      event_class: Projects::ProjectFeaturesChangedEvent,
      event_data: {
        project_id: 1,
        namespace_id: 2,
        root_namespace_id: 3,
        features: ['pages_access_level']
      },
      caches: [
        { type: :namespace, id: 3 }
      ]

    it_behaves_like 'ignores the published event' do
      let(:event) do
        Projects::ProjectFeaturesChangedEvent.new(
          data: {
            project_id: 1,
            namespace_id: 2,
            root_namespace_id: 3,
            features: ['unknown']
          }
        )
      end
    end
  end

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
        { type: :namespace, id: 5 }
      ]
  end
end
