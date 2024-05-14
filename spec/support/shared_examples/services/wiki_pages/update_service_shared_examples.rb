# frozen_string_literal: true

RSpec.shared_examples 'WikiPages::UpdateService#execute' do |container_type|
  let(:container) { create(container_type, :wiki_repo) }

  let(:user) { create(:user) }
  let(:page) { create(:wiki_page) }
  let(:page_title) { 'New Title' }

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

  it 'executes webhooks' do
    expect(service).to receive(:execute_hooks).once.with(WikiPage)

    service.execute(page)
  end

  it_behaves_like 'internal event tracking' do
    let(:event) { 'update_wiki_page' }
    let(:project) { container if container.is_a?(Project) }
    let(:namespace) { container.is_a?(Group) ? container : container.namespace }

    subject(:track_event) { service.execute(page) }
  end

  shared_examples 'adds activity event' do
    it 'adds a new wiki page activity event' do
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/216904
      pending('group wiki support') if container_type == :group

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
end
