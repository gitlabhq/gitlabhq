# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::EventsCache, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) { build_stubbed(:project, id: 1) }
  let(:issue) { build_stubbed(:issue, iid: 2) }

  let(:event_cache) { described_class.new(project) }

  def build_event(event)
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(event)
  end

  describe '#add' do
    it 'adds event to cache' do
      expect(Gitlab::Cache::Import::Caching).to receive(:list_add).with(
        'github-importer/events/1/Issue/2',
        an_instance_of(String),
        limit: described_class::MAX_NUMBER_OF_EVENTS
      )

      event_cache.add(issue, build_event({ event: 'closed' }))
    end

    context 'when events is too large to cache' do
      before do
        stub_const("#{described_class}::MAX_EVENT_SIZE", 1.byte)
      end

      it 'does not add event to cache' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:list_add)
        expect(Gitlab::GithubImport::Logger).to receive(:warn).with(
          message: 'Event too large to cache',
          project_id: project.id,
          github_identifiers: {
            event: 'closed',
            id: '99',
            issuable_iid: '2'
          }
        )

        event_cache.add(issue, build_event({ event: 'closed', id: '99', issue: { number: '2' } }))
      end
    end
  end

  describe '#events' do
    it 'retrieves the list of events from the cache in the correct order' do
      key = 'github-importer/events/1/Issue/2'

      Gitlab::Cache::Import::Caching.list_add(key, { event: 'merged', created_at: '2023-01-02T00:00:00Z' }.to_json)
      Gitlab::Cache::Import::Caching.list_add(key, { event: 'closed', created_at: '2023-01-03T00:00:00Z' }.to_json)
      Gitlab::Cache::Import::Caching.list_add(key, { event: 'commented', created_at: '2023-01-01T00:00:00Z' }.to_json)

      events = event_cache.events(issue).map(&:to_hash)

      expect(events).to match([
        a_hash_including(event: 'commented', created_at: '2023-01-01 00:00:00 UTC'),
        a_hash_including(event: 'merged', created_at: '2023-01-02 00:00:00 UTC'),
        a_hash_including(event: 'closed', created_at: '2023-01-03 00:00:00 UTC')
      ])
    end

    context 'when no event was added' do
      it 'returns an empty array' do
        expect(event_cache.events(issue)).to eq([])
      end
    end
  end

  describe '#delete' do
    it 'deletes the list' do
      expect(Gitlab::Cache::Import::Caching).to receive(:del).with('github-importer/events/1/Issue/2')

      event_cache.delete(issue)
    end
  end
end
