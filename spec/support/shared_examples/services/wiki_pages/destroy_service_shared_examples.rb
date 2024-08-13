# frozen_string_literal: true

RSpec.shared_examples 'WikiPages::DestroyService#execute' do |container_type|
  let(:container) { create(container_type) } # rubocop:disable Rails/SaveBang

  let(:user) { create(:user) }
  let(:page) { create(:wiki_page) }

  subject(:service) { described_class.new(container: container, current_user: user) }

  it 'executes webhooks' do
    expect(service).to receive(:execute_hooks).once.with(page)

    service.execute(page)
  end

  it_behaves_like 'internal event tracking' do
    let(:event) { 'delete_wiki_page' }
    let(:project) { container if container.is_a?(Project) }
    let(:namespace) { container.is_a?(Group) ? container : container.namespace }

    subject(:track_event) { service.execute(page) }
  end

  context 'when the deleted page is a template' do
    let(:page) { create(:wiki_page, title: "#{Wiki::TEMPLATES_DIR}/foobar") }

    it_behaves_like 'internal event tracking' do
      let(:event) { 'delete_wiki_page' }
      let(:project) { container if container.is_a?(Project) }
      let(:namespace) { container.is_a?(Group) ? container : container.namespace }
      let(:label) { 'template' }
      let(:property) { 'markdown' }

      subject(:track_event) { service.execute(page) }
    end
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

  context 'when the deletion fails' do
    before do
      expect(page).to receive(:delete).and_return(false)
    end

    it 'returns an error response' do
      response = service.execute(page)
      expect(response).to be_error
    end

    it 'does not increment the delete count if the deletion failed' do
      expect(Gitlab::InternalEvents).not_to receive(:track_event)

      service.execute(page)
    end
  end
end
