# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::DestroyService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project, developers: user_with_permissions, reporters: user_without_permissions) }
  let_it_be_with_refind(:incident) { create(:incident, project: project) }

  let!(:timeline_event) { create(:incident_management_timeline_event, incident: incident, project: project) }
  let(:current_user) { user_with_permissions }
  let(:params) { {} }
  let(:service) { described_class.new(timeline_event, current_user) }

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end

      it_behaves_like 'does not track incident management event', :incident_management_timeline_event_deleted
    end

    subject(:execute) { service.execute }

    context 'when current user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when user does not have permissions to remove timeline events' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when an error occurs during removal' do
      before do
        allow(timeline_event).to receive(:destroy).and_return(false)
        timeline_event.errors.add(:note, 'cannot be removed')
      end

      it_behaves_like 'error response', 'Timeline text cannot be removed'
    end

    context 'with success response' do
      it 'successfully returns the timeline event', :aggregate_failures do
        expect(execute).to be_success

        result = execute.payload[:timeline_event]
        expect(result).to be_a(::IncidentManagement::TimelineEvent)
        expect(result.id).to eq(timeline_event.id)
      end

      it 'creates a system note' do
        expect { execute }.to change { incident.notes.reload.count }.by(1)
      end

      it_behaves_like 'an incident management tracked event', :incident_management_timeline_event_deleted

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { project.namespace.reload }
        let(:category) { described_class.to_s }
        let(:user) { current_user }
        let(:action) { 'incident_management_timeline_event_deleted' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end
    end
  end
end
