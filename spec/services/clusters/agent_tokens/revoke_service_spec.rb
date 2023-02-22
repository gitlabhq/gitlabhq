# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokens::RevokeService, feature_category: :kubernetes_management do
  describe '#execute' do
    let(:agent) { create(:cluster_agent) }
    let(:agent_token) { create(:cluster_agent_token, agent: agent) }
    let(:project) { agent.project }
    let(:user) { agent.created_by_user }

    before do
      project.add_maintainer(user)
    end

    context 'when user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when user revokes agent token' do
        it 'succeeds' do
          described_class.new(token: agent_token, current_user: user).execute

          expect(agent_token.revoked?).to be true
        end
      end

      context 'when there is a validation failure' do
        before do
          agent_token.name = '' # make the record invalid, as we require a name to be present
        end

        it 'fails without raising an error', :aggregate_failures do
          result = described_class.new(token: agent_token, current_user: user).execute

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(["Name can't be blank"])
        end
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user) }

      before do
        project.add_guest(unauthorized_user)
      end

      context 'when user attempts to revoke agent token' do
        it 'fails' do
          described_class.new(token: agent_token, current_user: unauthorized_user).execute

          expect(agent_token.revoked?).to be false
        end
      end
    end
  end
end
