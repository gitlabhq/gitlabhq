require 'spec_helper'

describe WikiPages::DestroyService, services: true do
  let(:project) { create(:empty_project) }
<<<<<<< HEAD
  let(:user) { create(:user) }
  let(:page) { create(:wiki_page) }
=======
  let(:user)    { create(:user) }
  let(:page)    { create(:wiki_page) }
>>>>>>> master

  subject(:service) { described_class.new(project, user) }

  before do
<<<<<<< HEAD
    project.add_developer(user)
=======
    project.add_master(user)
>>>>>>> master
  end

  describe '#execute' do
    it 'executes webhooks' do
<<<<<<< HEAD
      expect(service).to receive(:execute_hooks).once
        .with(instance_of(WikiPage), 'delete')
=======
      expect(service).to receive(:execute_hooks).once.with(instance_of(WikiPage), 'delete')
>>>>>>> master

      service.execute(page)
    end
  end
end
