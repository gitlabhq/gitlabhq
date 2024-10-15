# frozen_string_literal: true

RSpec.shared_examples 'WikiPages::CreateService#execute' do |container_type|
  let(:container) { create(container_type, :wiki_repo) }
  let(:user) { create(:user, :with_namespace) }
  let(:page_title) { 'Title' }
  let(:container_key) { container.is_a?(Group) ? :namespace_id : :project_id }

  let(:opts) do
    {
      title: page_title,
      content: 'Content for wiki page',
      format: 'markdown'
    }
  end

  subject(:service) { described_class.new(container: container, current_user: user, params: opts) }

  it 'creates wiki page with valid attributes' do
    response = service.execute
    page = response.payload[:page]

    expect(response).to be_success
    expect(page).to be_valid
    expect(page).to be_persisted
    expect(page.title).to eq(opts[:title])
    expect(page.content).to eq(opts[:content])
    expect(page.format).to eq(opts[:format].to_sym)
  end

  it 'creates a WikiPage::Meta record' do
    expect { service.execute }.to change { WikiPage::Meta.count }.by 1

    expect(WikiPage::Meta.all.last).to have_attributes(
      title: page_title,
      container_key => container.id
    )
  end

  it 'executes webhooks' do
    expect(service).to receive(:execute_hooks).once.with(WikiPage)

    service.execute
  end

  describe 'internal event tracking' do
    let(:project) { container if container.is_a?(Project) }
    let(:namespace) { container.is_a?(Group) ? container : container.namespace }

    subject(:track_event) { service.execute }

    it_behaves_like 'internal event tracking' do
      let(:event) { 'create_wiki_page' }
    end

    context 'with group container', if: container_type == :group do
      it_behaves_like 'internal event tracking' do
        let(:event) { 'create_group_wiki_page' }
      end
    end

    context 'with project container', if: container_type == :project do
      it_behaves_like 'internal event not tracked' do
        let(:event) { 'create_group_wiki_page' }
      end
    end
  end

  context 'when the new page is a template' do
    let(:page_title) { "#{Wiki::TEMPLATES_DIR}/foobar" }

    it_behaves_like 'internal event tracking' do
      let(:event) { 'create_wiki_page' }
      let(:project) { container if container.is_a?(Project) }
      let(:namespace) { container.is_a?(Group) ? container : container.namespace }
      let(:label) { 'template' }
      let(:property) { 'markdown' }

      subject(:track_event) { service.execute }
    end
  end

  shared_examples 'correct event created' do
    it 'creates appropriate events' do
      expect { service.execute }.to change { Event.count }.by 1

      expect(Event.recent.first).to have_attributes(
        action: 'created',
        target: have_attributes(canonical_slug: page_title)
      )
    end
  end

  context 'the new page is at the top level' do
    let(:page_title) { 'root-level-page' }

    include_examples 'correct event created'
  end

  context 'the new page is in a subsection' do
    let(:page_title) { 'subsection/page' }

    include_examples 'correct event created'
  end

  context 'when the options are bad' do
    let(:page_title) { '' }

    it 'does not count a creation event' do
      expect(Gitlab::InternalEvents).not_to receive(:track_event)
    end

    it 'does not record the activity' do
      expect { service.execute }.not_to change { Event.count }
    end

    it 'reports the error' do
      response = service.execute
      page = response.payload[:page]

      expect(response).to be_error

      expect(page).to be_invalid
        .and have_attributes(errors: be_present)
    end
  end

  context 'when wiki create fails due to git error' do
    it 'catches the thrown error and returns a ServiceResponse error' do
      container = create(container_type, :wiki_repo)
      service = described_class.new(container: container, current_user: user, params: opts)

      allow(Gitlab::GitalyClient).to receive(:call) do
        raise GRPC::Unavailable, 'Gitaly broken in this spec'
      end

      result = service.execute
      expect(result).to be_error
      expect(result.message).to eq('Could not create wiki page')
    end
  end
end
