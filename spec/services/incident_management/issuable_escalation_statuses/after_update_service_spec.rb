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

  context 'with status attributes' do
    it 'updates an the associated alert with status changes' do
      expect(::AlertManagement::Alerts::UpdateService)
        .to receive(:new)
        .with(alert, current_user, { status: :acknowledged })
        .and_call_original

      expect(result).to be_success
      expect(alert.reload.status).to eq(escalation_status.reload.status)
    end

    context 'when incident is not associated with an alert' do
      before do
        alert.destroy!
      end

      it_behaves_like 'does not attempt to update the alert'
    end

    context 'when status was not changed' do
      let(:status_event) { :trigger }

      it_behaves_like 'does not attempt to update the alert'
    end
  end
end
