require 'spec_helper'

describe ForkNetworkMember do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:fork_network) }
  end

  describe 'destroying a ForkNetworkMember' do
    let(:fork_network_member) { create(:fork_network_member) }
    let(:fork_network) { fork_network_member.fork_network }

    it 'removes the fork network if it was the last member' do
      fork_network.fork_network_members.destroy_all

      expect(ForkNetwork.count).to eq(0)
    end

    it 'does not destroy the fork network if there are members left' do
      fork_network_member.destroy!

      # The root of the fork network is left
      expect(ForkNetwork.count).to eq(1)
    end
  end
end
