# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::AfterUpdateService do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status, :triggered) }
  let_it_be(:issue, reload: true) { escalation_status.issue }
  let_it_be(:project) { issue.project }
  let_it_be(:alert) { create(:alert_management_alert, issue: issue, project: project) }

  let(:status_event) { :acknowledge }
  let(:update_params) { { incident_management_issuable_escalation_status_attributes: { status_event: status_event } } }
  let(:service) { IncidentManagement::IssuableEscalationStatuses::AfterUpdateService.new(issue, current_user) }

  subject(:result) do
    issue.update!(update_params)
    service.execute
  end

  before do
    issue.project.add_developer(current_user)
  end

  shared_examples 'does not attempt to update the alert' do
    specify do
      expect(::AlertManagement::Alerts::UpdateService).not_to receive(:new)

      expect(result).to be_success
    end
  end

  shared_examples 'adds a status change system note' do
    specify do
      expect { result }.to change { issue.reload.notes.count }.by(1)
    end
  end

  shared_examples 'adds a status change timeline event' do
    specify do
      expect(IncidentManagement::TimelineEvents::CreateService)
        .to receive(:change_incident_status)
        .with(issue, current_user, escalation_status)
        .and_call_original

      expect { result }.to change { issue.reload.incident_management_timeline_events.count }.by(1)
    end
  end

  context 'with status attributes' do
    it_behaves_like 'adds a status change system note'
    it_behaves_like 'adds a status change timeline event'

    it 'updates the alert with the new alert status' do
      expect(::AlertManagement::Alerts::UpdateService).to receive(:new).once.and_call_original
      expect(described_class).to receive(:new).once.and_call_original

      expect { result }.to change { escalation_status.reload.acknowledged? }.to(true)
                       .and change { alert.reload.acknowledged? }.to(true)
    end

    context 'when incident is not associated with an alert' do
      before do
        alert.destroy!
      end

      it_behaves_like 'does not attempt to update the alert'
      it_behaves_like 'adds a status change system note'
      it_behaves_like 'adds a status change timeline event'
    end

    context 'when new status matches the current status' do
      let(:status_event) { :trigger }

      it_behaves_like 'does not attempt to update the alert'

      specify { expect { result }.not_to change { issue.reload.notes.count } }
      specify { expect { result }.not_to change { issue.reload.incident_management_timeline_events.count } }
    end
  end
end
