# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::ProcessAlertWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:settings) { create(:project_incident_management_setting, project: project, create_issue: true) }

  describe '#perform' do
    let_it_be(:started_at) { Time.now.rfc3339 }
    let_it_be(:payload) { { 'title' => 'title', 'start_time' => started_at } }
    let_it_be(:alert) { create(:alert_management_alert, project: project, payload: payload, started_at: started_at) }
    let(:created_issue) { Issue.last! }

    subject { described_class.new.perform(nil, nil, alert.id) }

    before do
      allow(Gitlab::AppLogger).to receive(:warn).and_call_original

      allow(AlertManagement::CreateAlertIssueService)
        .to receive(:new).with(alert, User.alert_bot)
        .and_call_original
    end

    shared_examples 'creates issue successfully' do
      it 'creates an issue' do
        expect(AlertManagement::CreateAlertIssueService)
          .to receive(:new).with(alert, User.alert_bot)

        expect { subject }.to change { Issue.count }.by(1)
      end

      it 'updates AlertManagement::Alert#issue_id' do
        subject

        expect(alert.reload.issue_id).to eq(created_issue.id)
      end

      it 'does not write a warning to log' do
        subject

        expect(Gitlab::AppLogger).not_to have_received(:warn)
      end
    end

    context 'with valid alert' do
      it_behaves_like 'creates issue successfully'

      context 'when alert cannot be updated' do
        let_it_be(:alert) { create(:alert_management_alert, :with_validation_errors, project: project, payload: payload) }

        it 'updates AlertManagement::Alert#issue_id' do
          expect { subject }.not_to change { alert.reload.issue_id }
        end

        it 'logs a warning' do
          subject

          expect(Gitlab::AppLogger).to have_received(:warn).with(
            message: 'Cannot process an Incident',
            issue_id: created_issue.id,
            alert_id: alert.id,
            errors: 'Hosts hosts array is over 255 chars'
          )
        end
      end

      context 'prometheus alert' do
        let_it_be(:alert) { create(:alert_management_alert, :prometheus, project: project, started_at: started_at) }

        it_behaves_like 'creates issue successfully'
      end
    end

    context 'with invalid alert' do
      let(:invalid_alert_id) { non_existing_record_id }

      subject { described_class.new.perform(nil, nil, invalid_alert_id) }

      it 'does not create issues' do
        expect(AlertManagement::CreateAlertIssueService).not_to receive(:new)

        expect { subject }.not_to change { Issue.count }
      end
    end
  end
end
