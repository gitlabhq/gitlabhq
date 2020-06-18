# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::ProcessAlertWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:settings) { create(:project_incident_management_setting, project: project, create_issue: true) }

  describe '#perform' do
    let(:alert_management_alert_id) { nil }
    let(:alert_payload) do
      {
        'annotations' => { 'title' => 'title' },
        'startsAt' => Time.now.rfc3339
      }
    end

    let(:created_issue) { Issue.last }

    subject { described_class.new.perform(project.id, alert_payload, alert_management_alert_id) }

    before do
      allow(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, alert_payload)
        .and_call_original
    end

    it 'creates an issue' do
      expect(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, alert_payload)

      expect { subject }.to change { Issue.count }.by(1)
    end

    context 'with invalid project' do
      let(:invalid_project_id) { non_existing_record_id }

      subject { described_class.new.perform(invalid_project_id, alert_payload) }

      it 'does not create issues' do
        expect(IncidentManagement::CreateIssueService).not_to receive(:new)

        expect { subject }.not_to change { Issue.count }
      end
    end

    context 'when alert_management_alert_id is present' do
      let!(:alert) { create(:alert_management_alert, project: project) }
      let(:alert_management_alert_id) { alert.id }

      before do
        allow(AlertManagement::Alert)
          .to receive(:find_by_id)
          .with(alert_management_alert_id)
          .and_return(alert)

        allow(Gitlab::AppLogger).to receive(:warn).and_call_original
      end

      context 'when alert can be updated' do
        it 'updates AlertManagement::Alert#issue_id' do
          subject

          expect(alert.reload.issue_id).to eq(created_issue.id)
        end

        it 'does not write a warning to log' do
          subject

          expect(Gitlab::AppLogger).not_to have_received(:warn)
        end
      end

      context 'when alert cannot be updated' do
        let(:alert) { create(:alert_management_alert, :with_validation_errors, project: project) }

        it 'updates AlertManagement::Alert#issue_id' do
          expect { subject }.not_to change { alert.reload.issue_id }
        end

        it 'logs a warning' do
          subject

          expect(Gitlab::AppLogger).to have_received(:warn).with(
            message: 'Cannot link an Issue with Alert',
            issue_id: created_issue.id,
            alert_id: alert_management_alert_id,
            alert_errors: { hosts: ['hosts array is over 255 chars'] }
          )
        end
      end
    end
  end
end
