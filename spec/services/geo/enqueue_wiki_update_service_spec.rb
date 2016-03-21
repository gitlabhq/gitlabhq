describe Geo::EnqueueWikiUpdateService, services: true do
  subject { Geo::EnqueueWikiUpdateService.new(project) }
  let(:project) { double(:project) }
  let(:fake_url) { 'git@localhost:repo/path.git' }
  let(:fake_id) { 999 }
  let(:queue) { subject.instance_variable_get(:@queue) }

  before(:each) do
    queue.empty!
    expect(project).to receive_message_chain(:wiki, :url_to_repo) { fake_url }
    expect(project).to receive(:id) { fake_id }
  end

  describe '#execute' do
    let(:stored_data) { queue.first }
    before(:each) { subject.execute }

    it 'persists id and clone_url to redis queue' do
      expect(stored_data).to have_key('id')
      expect(stored_data).to have_key('clone_url')
    end

    it 'persisted id is equal to original' do
      expect(stored_data['id']).to eq(fake_id)
    end

    it 'persisted clone_url is equal to original' do
      expect(stored_data['clone_url']).to eq(fake_url)
    end
  end
end
