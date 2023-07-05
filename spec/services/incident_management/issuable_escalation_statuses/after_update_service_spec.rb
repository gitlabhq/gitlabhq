# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::AfterUpdateService,
  feature_category: :incident_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status, :triggered) }
  let_it_be(:issue, reload: true) { escalation_status.issue }
  let_it_be(:project) { issue.project }

  let(:service) { described_class.new(issue, current_user) }

  subject(:result) do
    issue.update!(incident_management_issuable_escalation_status_attributes: update_params)
    service.execute
  end

  before do
    issue.project.add_developer(current_user)
  end

  context 'with status attributes' do
    let(:status_event) { :acknowledge }
    let(:update_params) { { status_event: status_event } }

    it 'adds a status change system note' do
      expect { result }.to change { issue.reload.notes.count }.by(1)
    end

    it 'adds a status change timeline event' do
      expect(IncidentManagement::TimelineEvents::CreateService)
        .to receive(:change_incident_status)
        .with(issue, current_user, escalation_status)
        .and_call_original

      expect { result }.to change { issue.reload.incident_management_timeline_events.count }.by(1)
    end
  end

  context 'with non-status attributes' do
    let(:update_params) { { updated_at: Time.current } }

    it 'does not add a status change system note or timeline event' do
      expect { result }
        .to not_change { issue.reload.notes.count }
        .and not_change { issue.reload.incident_management_timeline_events.count }
    end
  end
end
