# frozen_string_literal: true

RSpec.shared_examples 'WikiPages::UpdateService#execute' do |container_type|
  let(:container) { create(container_type, :wiki_repo) }

  let(:user) { create(:user) }
  let(:page) { create(:wiki_page, container: container) }
  let(:page_title) { 'New Title' }
  let(:container_key) { container.is_a?(Group) ? :namespace_id : :project_id }

  let(:opts) do
    {
      content: 'New content for wiki page',
      format: 'markdown',
      message: 'New wiki message',
      title: page_title
    }
  end

  subject(:service) { described_class.new(container: container, current_user: user, params: opts) }

  it 'updates the wiki page' do
    response = service.execute(page)
    updated_page = response.payload[:page]

    expect(response).to be_success
    expect(updated_page).to be_valid
    expect(updated_page.message).to eq(opts[:message])
    expect(updated_page.content).to eq(opts[:content])
    expect(updated_page.format).to eq(opts[:format].to_sym)
    expect(updated_page.title).to eq(page_title)
  end

  it 'creates the WikiPage::Meta record if it does not exist' do
    expect { service.execute(page) }.to change { WikiPage::Meta.count }.by 1

    expect(WikiPage::Meta.all.last).to have_attributes(
      title: page_title,
      container_key => container.id
    )
  end

  context 'when WikiPage::Meta record exists' do
    let!(:wiki_page_meta) { create(:wiki_page_meta, container: container) }

    before do
      allow(WikiPage::Meta).to receive(:find_by_canonical_slug).and_return(wiki_page_meta)
    end

    it 'doesn not create a WikiPage::Meta record' do
      expect { service.execute(page) }.to change { WikiPage::Meta.count }.by 0
    end
  end

  it 'executes webhooks' do
    expect(service).to receive(:execute_hooks).once.with(WikiPage)

    service.execute(page)
  end

  describe 'internal event tracking' do
    let(:project) { container if container.is_a?(Project) }
    let(:namespace) { container.is_a?(Group) ? container : container.namespace }

    subject(:track_event) { service.execute(page) }

    it_behaves_like 'internal event tracking' do
      let(:event) { 'update_wiki_page' }
    end

    context 'with group container', if: container_type == :group do
      it_behaves_like 'internal event tracking' do
        let(:event) { 'update_group_wiki_page' }
      end
    end

    context 'with project container', if: container_type == :project do
      it_behaves_like 'internal event not tracked' do
        let(:event) { 'update_group_wiki_page' }
      end
    end
  end

  context 'when the updated page is a template' do
    let(:page) { create(:wiki_page, title: "#{Wiki::TEMPLATES_DIR}/foobar") }

    it_behaves_like 'internal event tracking' do
      let(:event) { 'update_wiki_page' }
      let(:project) { container if container.is_a?(Project) }
      let(:namespace) { container.is_a?(Group) ? container : container.namespace }
      let(:label) { 'template' }
      let(:property) { 'markdown' }

      subject(:track_event) { service.execute(page) }
    end
  end

  shared_examples 'adds activity event' do
    it 'adds a new wiki page activity event' do
      expect { service.execute(page) }.to change { Event.count }.by 1

      expect(Event.recent.first).to have_attributes(
        action: 'updated',
        wiki_page: page,
        target_title: page.title
      )
    end
  end

  context 'the page is at the top level' do
    let(:page_title) { 'Top level page' }

    include_examples 'adds activity event'
  end

  context 'the page is in a subsection' do
    let(:page_title) { 'Subsection / secondary page' }

    include_examples 'adds activity event'
  end

  context 'when the options are bad' do
    let(:page_title) { '' }

    it 'does not count an edit event' do
      expect(Gitlab::InternalEvents).not_to receive(:track_event)

      service.execute(page)
    end

    it 'does not record the activity' do
      expect { service.execute page }.not_to change { Event.count }
    end

    it 'reports the error' do
      response = service.execute(page)
      page = response.payload[:page]

      expect(response).to be_error
      expect(page).to be_invalid
        .and have_attributes(errors: be_present)
    end
  end

  context 'when wiki update fails due to git error' do
    it 'catches the thrown error and returns a ServiceResponse error' do
      container = create(container_type, :wiki_repo)
      page = create(:wiki_page, container: container)
      service = described_class.new(container: container, current_user: user, params: opts)

      allow(Gitlab::GitalyClient).to receive(:call) do
        raise GRPC::Unavailable, 'Gitaly broken in this spec'
      end

      result = service.execute(page)
      expect(result).to be_error
      expect(result.message).to eq('Could not update wiki page')
    end
  end
end
