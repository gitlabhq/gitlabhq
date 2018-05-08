require 'spec_helper'

describe WikiPages::CreateService do
  let(:project) { create(:project, :wiki_repo) }
  let(:user) { create(:user) }

  let(:opts) do
    {
      title: 'Title',
      content: 'Content for wiki page',
      format: 'markdown'
    }
  end

  subject(:service) { described_class.new(project, user, opts) }

  before do
    project.add_master(user)
  end

  describe '#execute' do
    it 'creates wiki page with valid attributes' do
      page = service.execute

      expect(page).to be_valid
      expect(page).to have_attributes(title: opts[:title], content: opts[:content], format: opts[:format].to_sym)
    end

    it 'executes webhooks' do
      expect(service).to receive(:execute_hooks).once.with(instance_of(WikiPage), 'create')

      service.execute
    end
  end
end
