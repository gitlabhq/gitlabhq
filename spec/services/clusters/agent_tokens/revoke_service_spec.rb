# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokens::RevokeService, feature_category: :deployment_management do
  describe '#execute' do
    subject { described_class.new(token: agent_token, current_user: user).execute }

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
          subject

          expect(agent_token.revoked?).to be true
        end

        it 'creates an activity event' do
          expect { subject }.to change { ::Clusters::Agents::ActivityEvent.count }.by(1)

          event = agent.activity_events.last

          expect(event).to have_attributes(
            kind: 'token_revoked',
            level: 'info',
            recorded_at: agent_token.reload.updated_at,
            user: user,
            agent_token: agent_token
          )
        end
      end

      context 'when there is a validation failure' do
        before do
          agent_token.name = '' # make the record invalid, as we require a name to be present
        end

        it 'fails without raising an error', :aggregate_failures do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq(["Name can't be blank"])
        end

        it 'does not create an activity event' do
          expect { subject }.not_to change { ::Clusters::Agents::ActivityEvent.count }
        end
      end
    end

    context 'when user is not authorized' do
      let(:user) { create(:user) }

      before do
        project.add_guest(user)
      end

      context 'when user attempts to revoke agent token' do
        it 'fails' do
          subject

          expect(agent_token.revoked?).to be false
        end
      end
    end
  end
end
