# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::CreateActivityEventService, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }
  let_it_be(:token) { create(:cluster_agent_token, agent: agent) }
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    let(:params) do
      {
        kind: :token_created,
        level: :info,
        recorded_at: token.created_at,
        user: user,
        agent_token: token
      }
    end

    subject { described_class.new(agent, **params).execute }

    it 'creates an activity event record' do
      expect { subject }.to change(agent.activity_events, :count).from(0).to(1)

      event = agent.activity_events.last

      expect(event).to have_attributes(
        kind: 'token_created',
        level: 'info',
        recorded_at: token.reload.created_at,
        user: user,
        agent_token_id: token.id
      )
    end

    it 'schedules the cleanup worker' do
      expect(Clusters::Agents::DeleteExpiredEventsWorker).to receive(:perform_at)
        .with(1.hour.from_now.change(min: agent.id % 60), agent.id)

      subject
    end

    context 'when activity event creation fails' do
      let(:params) { {} }

      it 'tracks the exception without raising' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(ActiveRecord::RecordInvalid), agent_id: agent.id)

        subject
      end
    end
  end
end
