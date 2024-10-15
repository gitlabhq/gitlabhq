# frozen_string_literal: true

RSpec.shared_examples 'WikiPages::DestroyService#execute' do |container_type|
  let(:container) { create(container_type) } # rubocop:disable Rails/SaveBang

  let(:user) { create(:user) }
  let(:page) { create(:wiki_page) }
  let!(:wiki_page_meta) { create(:wiki_page_meta, container: container) }

  subject(:service) { described_class.new(container: container, current_user: user) }

  it 'executes webhooks' do
    expect(service).to receive(:execute_hooks).once.with(page)

    service.execute(page)
  end

  describe 'internal event tracking' do
    let(:project) { container if container.is_a?(Project) }
    let(:namespace) { container.is_a?(Group) ? container : container.namespace }

    subject(:track_event) { service.execute(page) }

    it_behaves_like 'internal event tracking' do
      let(:event) { 'delete_wiki_page' }
    end

    context 'with group container', if: container_type == :group do
      it_behaves_like 'internal event tracking' do
        let(:event) { 'delete_group_wiki_page' }
      end
    end

    context 'with project container', if: container_type == :project do
      it_behaves_like 'internal event not tracked' do
        let(:event) { 'delete_group_wiki_page' }
      end
    end

    context 'when the deleted page is a template' do
      let(:page) { create(:wiki_page, title: "#{Wiki::TEMPLATES_DIR}/foobar") }

      it_behaves_like 'internal event tracking' do
        let(:event) { 'delete_wiki_page' }
        let(:label) { 'template' }
        let(:property) { 'markdown' }
      end
    end
  end

  # This test fails, because deleting a page seems to orphan WikiPage;:Meta and WikiPage::Slug records,
  # but it's included for completeness for now.
  pending 'deletes a WikiPage::Meta record' do
    expect { service.execute(page) }.to change { WikiPage::Meta.count }.by(-1)
  end

  it 'creates a new wiki page deletion event' do
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

  context 'when wiki delete fails due to git error' do
    it 'catches the thrown error and returns a ServiceResponse error' do
      container = create(container_type, :wiki_repo)
      page = create(:wiki_page, container: container)
      service = described_class.new(container: container, current_user: user)

      allow(Gitlab::GitalyClient).to receive(:call) do
        raise GRPC::Unavailable, 'Gitaly broken in this spec'
      end

      result = service.execute(page)
      expect(result).to be_error
      expect(result.message).to eq('Could not delete wiki page')
    end
  end
end
