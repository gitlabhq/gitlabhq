# frozen_string_literal: true

RSpec.shared_examples 'WikiPages::DestroyService#execute' do |container_type|
  let(:container) { create(container_type) }

  let(:user) { create(:user) }
  let(:page) { create(:wiki_page) }

  subject(:service) { described_class.new(container: container, current_user: user) }

  it 'executes webhooks' do
    expect(service).to receive(:execute_hooks).once.with(page)

    service.execute(page)
  end

  it 'increments the delete count' do
    counter = Gitlab::UsageDataCounters::WikiPageCounter

    expect { service.execute(page) }.to change { counter.read(:delete) }.by 1
  end

  it 'creates a new wiki page deletion event' do
    # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/216904
    pending('group wiki support') if container_type == :group

    expect { service.execute(page) }.to change { Event.count }.by 1

    expect(Event.recent.first).to have_attributes(
      action: 'destroyed',
      target: have_attributes(canonical_slug: page.slug)
    )
  end

  it 'does not increment the delete count if the deletion failed' do
    counter = Gitlab::UsageDataCounters::WikiPageCounter

    expect { service.execute(nil) }.not_to change { counter.read(:delete) }
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
