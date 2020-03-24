# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::DestroyService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:page) { create(:wiki_page) }

  subject(:service) { described_class.new(project, user) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    it 'executes webhooks' do
      expect(service).to receive(:execute_hooks).once.with(page)

      service.execute(page)
    end

    it 'increments the delete count' do
      counter = Gitlab::UsageDataCounters::WikiPageCounter

      expect { service.execute(page) }.to change { counter.read(:delete) }.by 1
    end

    it 'creates a new wiki page deletion event' do
      expect { service.execute(page) }.to change { Event.count }.by 1

      expect(Event.recent.first).to have_attributes(
        action: Event::DESTROYED,
        target: have_attributes(canonical_slug: page.slug)
      )
    end

    it 'does not increment the delete count if the deletion failed' do
      counter = Gitlab::UsageDataCounters::WikiPageCounter

      expect { service.execute(nil) }.not_to change { counter.read(:delete) }
    end
  end

  context 'the feature is disabled' do
    before do
      stub_feature_flags(wiki_events: false)
    end

    it 'does not record the activity' do
      expect { service.execute(page) }.not_to change(Event, :count)
    end
  end
end
