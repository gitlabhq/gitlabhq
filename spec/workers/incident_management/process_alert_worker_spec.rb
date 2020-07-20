# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::ProcessAlertWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:settings) { create(:project_incident_management_setting, project: project, create_issue: true) }

  describe '#perform' do
    let_it_be(:started_at) { Time.now.rfc3339 }
    let_it_be(:payload) { { 'title' => 'title', 'start_time' => started_at } }
    let_it_be(:parsed_payload) { Gitlab::Alerting::NotificationPayloadParser.call(payload, project) }
    let_it_be(:alert) { create(:alert_management_alert, project: project, payload: payload, started_at: started_at) }
    let(:created_issue) { Issue.last! }

    subject { described_class.new.perform(nil, nil, alert.id) }

    before do
      allow(IncidentManagement::CreateIssueService)
        .to receive(:new).with(alert.project, parsed_payload)
        .and_call_original
    end

    it 'creates an issue' do
      expect(IncidentManagement::CreateIssueService)
        .to receive(:new).with(alert.project, parsed_payload)

      expect { subject }.to change { Issue.count }.by(1)
    end

    context 'with invalid alert' do
      let(:invalid_alert_id) { non_existing_record_id }

      subject { described_class.new.perform(nil, nil, invalid_alert_id) }

      it 'does not create issues' do
        expect(IncidentManagement::CreateIssueService).not_to receive(:new)

        expect { subject }.not_to change { Issue.count }
      end
    end

    context 'with valid alert' do
      before do
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

        context 'when alert cannot be updated' do
          let_it_be(:alert) { create(:alert_management_alert, :with_validation_errors, project: project, payload: payload) }

          it 'updates AlertManagement::Alert#issue_id' do
            expect { subject }.not_to change { alert.reload.issue_id }
          end

          it 'logs a warning' do
            subject

            expect(Gitlab::AppLogger).to have_received(:warn).with(
              message: 'Cannot link an Issue with Alert',
              issue_id: created_issue.id,
              alert_id: alert.id,
              alert_errors: { hosts: ['hosts array is over 255 chars'] }
            )
          end
        end
      end
    end
  end
end
