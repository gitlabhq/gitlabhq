# rubocop:disable RSpec/FilePath
require 'spec_helper'

describe Projects::TransferService, services: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  subject { described_class.new(project, user) }

  before do
    group.add_owner(user)
  end

  context 'when running on a primary node' do
    let!(:geo_node) { create(:geo_node, :primary, :current) }

    it 'logs an event to the Geo event log' do
      expect { subject.execute(group) }.to change(Geo::RepositoryRenamedEvent, :count).by(1)
    end
  end
end
