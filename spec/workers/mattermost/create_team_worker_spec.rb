require 'spec_helper'

describe Mattermost::CreateTeamWorker do
  let(:group) { create(:group, path: 'path', name: 'name') }
  let(:admin) { create(:admin) }

  describe '.perform' do
    subject { described_class.new.perform(group.id, admin.id) }

    context 'succesfull request to mattermost' do
      before do
        allow_any_instance_of(Mattermost::Team).
          to receive(:create).
          with(group, {}).
          and_return('name' => 'my team', 'id' => 'sjfkdlwkdjfwlkfjwf')
      end

      it 'creates a new chat team' do
        expect { subject }.to change { ChatTeam.count }.from(0).to(1)
      end
    end

    context 'connection trouble' do
      before do
        allow_any_instance_of(Mattermost::Team).
          to receive(:create).
          with(group, {}).
          and_raise(Mattermost::ClientError.new('Undefined error'))
      end

      it 'does not rescue the error' do
        expect { subject }.to raise_error(Mattermost::ClientError)
      end
    end
  end
end
