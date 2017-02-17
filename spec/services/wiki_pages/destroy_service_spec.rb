require 'spec_helper'

describe WikiPages::DestroyService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:wiki_page) { create(:wiki_page) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    before do
      allow(service).to receive(:execute_hooks)
      project.add_master(user)
    end

    it 'executes webhooks' do
      service.execute(wiki_page)

      expect(service).to have_received(:execute_hooks).once.with(wiki_page, 'delete')
    end
  end
end
