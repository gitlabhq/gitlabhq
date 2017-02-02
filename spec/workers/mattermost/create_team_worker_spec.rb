require 'spec_helper'

describe Mattermost::CreateTeamWorker do
  let(:group) { create(:group, path: 'path', name: 'name') }
  let(:admin) { create(:admin) }

  describe '.perform' do
    subject { described_class.new.perform(group.id, admin.id) }

    before do
      allow_any_instance_of(Mattermost::Team).
        to receive(:create).
        with(name: "path", display_name: "name", type: "O").
        and_return('name' => 'my team', 'id' => 'sjfkdlwkdjfwlkfjwf')
    end

    it 'creates a new chat team' do
      expect { subject }.to change { ChatTeam.count }.from(0).to(1)
    end
  end
end
