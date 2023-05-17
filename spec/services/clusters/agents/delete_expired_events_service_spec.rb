# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::DeleteExpiredEventsService, feature_category: :deployment_management do
  let_it_be(:agent) { create(:cluster_agent) }

  describe '#execute' do
    let_it_be(:event1) { create(:agent_activity_event, agent: agent, recorded_at: 1.hour.ago) }
    let_it_be(:event2) { create(:agent_activity_event, agent: agent, recorded_at: 2.hours.ago) }
    let_it_be(:event3) { create(:agent_activity_event, agent: agent, recorded_at: 3.hours.ago) }
    let_it_be(:event4) { create(:agent_activity_event, agent: agent, recorded_at: 4.hours.ago) }
    let_it_be(:event5) { create(:agent_activity_event, agent: agent, recorded_at: 5.hours.ago) }

    let(:deletion_cutoff) { 1.day.ago }

    subject { described_class.new(agent).execute }

    before do
      allow(agent).to receive(:activity_event_deletion_cutoff).and_return(deletion_cutoff)
    end

    it 'does not delete events if the limit has not been reached' do
      expect { subject }.not_to change(agent.activity_events, :count)
    end

    context 'there are more events than the limit' do
      let(:deletion_cutoff) { event3.recorded_at }

      it 'removes events to remain at the limit, keeping the most recent' do
        expect { subject }.to change(agent.activity_events, :count).from(5).to(3)
        expect(agent.activity_events).to contain_exactly(event1, event2, event3)
      end
    end
  end
end
