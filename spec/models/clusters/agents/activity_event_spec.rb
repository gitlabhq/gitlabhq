# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::ActivityEvent do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:agent_token).class_name('Clusters::AgentToken').optional }

  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to validate_presence_of(:level) }
  it { is_expected.to validate_presence_of(:recorded_at) }
  it { is_expected.to nullify_if_blank(:detail) }

  describe 'scopes' do
    let_it_be(:agent) { create(:cluster_agent) }

    describe '.in_timeline_order' do
      let_it_be(:recorded_at) { 1.hour.ago }
      let_it_be(:event1) { create(:agent_activity_event, agent: agent, recorded_at: recorded_at) }
      let_it_be(:event2) { create(:agent_activity_event, agent: agent, recorded_at: Time.current) }
      let_it_be(:event3) { create(:agent_activity_event, agent: agent, recorded_at: recorded_at) }

      subject { described_class.in_timeline_order }

      it 'sorts by recorded_at: :desc, id: :desc' do
        is_expected.to eq([event2, event3, event1])
      end
    end

    describe '.recorded_before' do
      let_it_be(:event1) { create(:agent_activity_event, agent: agent, recorded_at: 1.hour.ago) }
      let_it_be(:event2) { create(:agent_activity_event, agent: agent, recorded_at: 2.hours.ago) }
      let_it_be(:event3) { create(:agent_activity_event, agent: agent, recorded_at: 3.hours.ago) }

      let(:cutoff) { event2.recorded_at }

      subject { described_class.recorded_before(cutoff) }

      it 'returns only events recorded before the cutoff' do
        is_expected.to contain_exactly(event3)
      end
    end
  end
end
