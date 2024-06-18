# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokens::TrackUsageService, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }

  describe '#execute', :clean_gitlab_redis_cache do
    let(:agent_token) { create(:cluster_agent_token, agent: agent) }

    subject { described_class.new(agent_token).execute }

    context 'when last_used_at was updated recently' do
      before do
        agent_token.update!(last_used_at: 10.minutes.ago)
      end

      it 'updates cache but not database' do
        expect { subject }.not_to change { agent_token.reload.read_attribute(:last_used_at) }

        expect_redis_update
      end
    end

    context 'when last_used_at was not updated recently' do
      it 'updates cache and database' do
        does_db_update
        expect_redis_update
      end

      context 'with invalid token' do
        before do
          agent_token.description = SecureRandom.hex(2000)
        end

        it 'still updates caches and database' do
          expect(agent_token).to be_invalid

          does_db_update
          expect_redis_update
        end
      end

      context 'agent is not connected' do
        before do
          allow(agent).to receive(:connected?).and_return(false)
        end

        it 'creates an activity event' do
          expect { subject }.to change { agent.activity_events.count }

          event = agent.activity_events.last
          expect(event).to have_attributes(
            kind: 'agent_connected',
            level: 'info',
            recorded_at: agent_token.reload.read_attribute(:last_used_at),
            agent_token: agent_token
          )
        end
      end

      context 'agent is connected' do
        before do
          allow(agent).to receive(:connected?).and_return(true)
        end

        it 'does not create an activity event' do
          expect { subject }.not_to change { agent.activity_events.count }
        end
      end
    end

    context 'when usage tracking raises an error' do
      before do
        allow(agent_token).to receive(:update_columns).and_raise(ActiveRecord::NotNullViolation, 'error message')
      end

      it 'tracks the exception without raising' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(ActiveRecord::NotNullViolation), agent_id: agent.id)

        subject
      end
    end

    def expect_redis_update
      Gitlab::Redis::Cache.with do |redis|
        redis_key = "cache:#{agent_token.class}:#{agent_token.id}:attributes"
        expect(redis.get(redis_key)).to be_present
      end
    end

    def does_db_update
      expect { subject }.to change { agent_token.reload.read_attribute(:last_used_at) }
    end
  end
end
