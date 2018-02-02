require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171114104051_remove_empty_fork_networks.rb')

describe RemoveEmptyForkNetworks, :migration do
  let!(:fork_networks) { table(:fork_networks) }

  let(:deleted_project) { create(:project) }
  let!(:empty_network) { create(:fork_network, id: 1, root_project_id: deleted_project.id) }
  let!(:other_network) { create(:fork_network, id: 2, root_project_id: create(:project).id) }

  before do
    deleted_project.destroy!
  end

  after do
    Upload.reset_column_information
  end

  it 'deletes only the fork network without members' do
    expect(fork_networks.count).to eq(2)

    migrate!

    expect(fork_networks.find_by(id: empty_network.id)).to be_nil
    expect(fork_networks.find_by(id: other_network.id)).not_to be_nil
    expect(fork_networks.count).to eq(1)
  end
end
