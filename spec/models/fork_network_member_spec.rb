# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkNetworkMember do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:fork_network) }
  end

  describe 'destroying a ForkNetworkMember' do
    let(:fork_network_member) { create(:fork_network_member) }
    let(:fork_network) { fork_network_member.fork_network }

    it 'removes the fork network if it was the last member' do
      fork_network.fork_network_members.destroy_all # rubocop: disable Cop/DestroyAll

      expect(ForkNetwork.count).to eq(0)
    end

    it 'does not destroy the fork network if there are members left' do
      fork_network_member.destroy!

      # The root of the fork network is left
      expect(ForkNetwork.count).to eq(1)
    end
  end

  describe '#by_projects' do
    let_it_be(:fork_network_member_1) { create(:fork_network_member) }
    let_it_be(:fork_network_member_2) { create(:fork_network_member) }

    it 'returns fork network members by project ids' do
      expect(
        described_class.by_projects(
          [fork_network_member_1.project_id, fork_network_member_2.project_id]
        )
      ).to match_array([fork_network_member_1, fork_network_member_2])
    end
  end

  describe '#with_fork_network' do
    let_it_be(:fork_network_member_1) { create(:fork_network_member) }
    let_it_be(:fork_network_member_2) { create(:fork_network_member) }

    it 'avoids N+1 queries' do
      query_count = ActiveRecord::QueryRecorder.new do
        described_class.all.with_fork_network.find_each(&:fork_network)
      end

      expect(query_count).not_to exceed_query_limit(1)
    end
  end
end
