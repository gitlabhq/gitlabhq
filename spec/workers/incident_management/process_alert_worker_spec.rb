# frozen_string_literal: true

require 'spec_helper'

describe IncidentManagement::ProcessAlertWorker do
  let_it_be(:project) { create(:project) }

  describe '#perform' do
    let(:alert_management_alert_id) { nil }
    let(:alert_payload) { { alert: 'payload' } }
    let(:new_issue) { create(:issue, project: project) }
    let(:create_issue_service) { instance_double(IncidentManagement::CreateIssueService, execute: new_issue) }

    subject { described_class.new.perform(project.id, alert_payload, alert_management_alert_id) }

    before do
      allow(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, alert_payload)
        .and_return(create_issue_service)
    end

    it 'calls create issue service' do
      expect(Project).to receive(:find_by_id).and_call_original

      expect(IncidentManagement::CreateIssueService)
        .to receive(:new).with(project, alert_payload)
        .and_return(create_issue_service)

      expect(create_issue_service).to receive(:execute)

      subject
    end

    context 'with invalid project' do
      let(:invalid_project_id) { 0 }

      subject { described_class.new.perform(invalid_project_id, alert_payload) }

      it 'does not create issues' do
        expect(Project).to receive(:find_by_id).and_call_original
        expect(IncidentManagement::CreateIssueService).not_to receive(:new)

        subject
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

        allow(Gitlab::GitLogger).to receive(:warn).and_call_original
      end

      context 'when alert can be updated' do
        it 'updates AlertManagement::Alert#issue_id' do
          expect { subject }.to change { alert.reload.issue_id }.to(new_issue.id)
        end

        it 'does not write a warning to log' do
          subject

          expect(Gitlab::GitLogger).not_to have_received(:warn)
        end
      end

      context 'when alert cannot be updated' do
        before do
          # invalidate alert
          too_many_hosts = Array.new(AlertManagement::Alert::HOSTS_MAX_LENGTH + 1) { |_| 'host' }
          alert.update_columns(hosts: too_many_hosts)
        end

        it 'updates AlertManagement::Alert#issue_id' do
          expect { subject }.not_to change { alert.reload.issue_id }
        end

        it 'writes a worning to log' do
          subject

          expect(Gitlab::GitLogger).to have_received(:warn).with(
            message: 'Cannot link an Issue with Alert',
            issue_id: new_issue.id,
            alert_id: alert_management_alert_id,
            alert_errors: { hosts: ['hosts array is over 255 chars'] }
          )
        end
      end
    end
  end
end
