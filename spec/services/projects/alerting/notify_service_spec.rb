# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Alerting::NotifyService do
  let_it_be(:project, reload: true) { create(:project) }

  before do
    # We use `let_it_be(:project)` so we make sure to clear caches
    project.clear_memoization(:licensed_feature_available)
    allow(ProjectServiceWorker).to receive(:perform_async)
  end

  shared_examples 'processes incident issues' do
    let(:create_incident_service) { spy }

    before do
      allow_any_instance_of(AlertManagement::Alert).to receive(:execute_services)
    end

    it 'processes issues' do
      expect(IncidentManagement::ProcessAlertWorker)
        .to receive(:perform_async)
        .with(nil, nil, kind_of(Integer))
        .once

      Sidekiq::Testing.inline! do
        expect(subject).to be_success
      end
    end
  end

  shared_examples 'sends notification email' do
    let(:notification_service) { spy }

    it 'sends a notification for firing alerts only' do
      expect(NotificationService)
        .to receive(:new)
        .and_return(notification_service)

      expect(notification_service)
        .to receive_message_chain(:async, :prometheus_alerts_fired)

      expect(subject).to be_success
    end
  end

  shared_examples 'does not process incident issues' do
    it 'does not process issues' do
      expect(IncidentManagement::ProcessAlertWorker)
        .not_to receive(:perform_async)

      expect(subject).to be_success
    end
  end

  shared_examples 'does not process incident issues due to error' do |http_status:|
    it 'does not process issues' do
      expect(IncidentManagement::ProcessAlertWorker)
        .not_to receive(:perform_async)

      expect(subject).to be_error
      expect(subject.http_status).to eq(http_status)
    end
  end

  describe '#execute' do
    let(:token) { 'invalid-token' }
    let(:starts_at) { Time.current.change(usec: 0) }
    let(:fingerprint) { 'testing' }
    let(:service) { described_class.new(project, nil, payload) }
    let(:payload_raw) do
      {
        title: 'alert title',
        start_time: starts_at.rfc3339,
        severity: 'low',
        monitoring_tool: 'GitLab RSpec',
        service: 'GitLab Test Suite',
        description: 'Very detailed description',
        hosts: ['1.1.1.1', '2.2.2.2'],
        fingerprint: fingerprint
      }.with_indifferent_access
    end
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }

    subject { service.execute(token) }

    context 'with activated Alerts Service' do
      let!(:alerts_service) { create(:alerts_service, project: project) }

      context 'with valid token' do
        let(:token) { alerts_service.token }
        let(:incident_management_setting) { double(send_email?: email_enabled, create_issue?: issue_enabled) }
        let(:email_enabled) { false }
        let(:issue_enabled) { false }

        before do
          allow(service)
            .to receive(:incident_management_setting)
            .and_return(incident_management_setting)
        end

        context 'with valid payload' do
          shared_examples 'assigns the alert properties' do
            it 'ensure that created alert has all data properly assigned' do
              subject

              expect(last_alert_attributes).to match(
                project_id: project.id,
                title: payload_raw.fetch(:title),
                started_at: Time.zone.parse(payload_raw.fetch(:start_time)),
                severity: payload_raw.fetch(:severity),
                status: AlertManagement::Alert::STATUSES[:triggered],
                events: 1,
                hosts: payload_raw.fetch(:hosts),
                payload: payload_raw.with_indifferent_access,
                issue_id: nil,
                description: payload_raw.fetch(:description),
                monitoring_tool: payload_raw.fetch(:monitoring_tool),
                service: payload_raw.fetch(:service),
                fingerprint: Digest::SHA1.hexdigest(fingerprint),
                ended_at: nil,
                prometheus_alert_id: nil,
                environment_id: nil
              )
            end
          end

          let(:last_alert_attributes) do
            AlertManagement::Alert.last.attributes
              .except('id', 'iid', 'created_at', 'updated_at')
              .with_indifferent_access
          end

          it_behaves_like 'creates an alert management alert'
          it_behaves_like 'assigns the alert properties'

          context 'existing alert with same fingerprint' do
            let(:fingerprint_sha) { Digest::SHA1.hexdigest(fingerprint) }
            let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint_sha) }

            it_behaves_like 'adds an alert management alert event'

            context 'existing alert is resolved' do
              let!(:alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: fingerprint_sha) }

              it_behaves_like 'creates an alert management alert'
              it_behaves_like 'assigns the alert properties'
            end

            context 'existing alert is ignored' do
              let!(:alert) { create(:alert_management_alert, :ignored, project: project, fingerprint: fingerprint_sha) }

              it_behaves_like 'adds an alert management alert event'
            end

            context 'two existing alerts, one resolved one open' do
              let!(:resolved_existing_alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: fingerprint_sha) }
              let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint_sha) }

              it_behaves_like 'adds an alert management alert event'
            end
          end

          context 'with a minimal payload' do
            let(:payload_raw) do
              {
                title: 'alert title',
                start_time: starts_at.rfc3339
              }
            end

            it_behaves_like 'creates an alert management alert'

            it 'created alert has all data properly assigned' do
              subject

              expect(last_alert_attributes).to match(
                project_id: project.id,
                title: payload_raw.fetch(:title),
                started_at: Time.zone.parse(payload_raw.fetch(:start_time)),
                severity: 'critical',
                status: AlertManagement::Alert::STATUSES[:triggered],
                events: 1,
                hosts: [],
                payload: payload_raw.with_indifferent_access,
                issue_id: nil,
                description: nil,
                monitoring_tool: nil,
                service: nil,
                fingerprint: nil,
                ended_at: nil,
                prometheus_alert_id: nil,
                environment_id: nil
              )
            end
          end
        end

        it_behaves_like 'does not process incident issues'

        context 'issue enabled' do
          let(:issue_enabled) { true }

          it_behaves_like 'processes incident issues'

          context 'with an invalid payload' do
            before do
              allow(Gitlab::Alerting::NotificationPayloadParser)
                .to receive(:call)
                .and_raise(Gitlab::Alerting::NotificationPayloadParser::BadPayloadError)
            end

            it_behaves_like 'does not process incident issues due to error', http_status: :bad_request
            it_behaves_like 'does not an create alert management alert'
          end

          context 'when alert already exists' do
            let(:fingerprint_sha) { Digest::SHA1.hexdigest(fingerprint) }
            let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint_sha) }

            context 'when existing alert does not have an associated issue' do
              it_behaves_like 'processes incident issues'
            end

            context 'when existing alert has an associated issue' do
              let!(:alert) { create(:alert_management_alert, :with_issue, project: project, fingerprint: fingerprint_sha) }

              it_behaves_like 'does not process incident issues'
            end
          end
        end

        context 'with emails turned on' do
          let(:email_enabled) { true }

          it_behaves_like 'sends notification email'
        end
      end

      context 'with invalid token' do
        it_behaves_like 'does not process incident issues due to error', http_status: :unauthorized
        it_behaves_like 'does not an create alert management alert'
      end

      context 'with deactivated Alerts Service' do
        let!(:alerts_service) { create(:alerts_service, :inactive, project: project) }

        it_behaves_like 'does not process incident issues due to error', http_status: :forbidden
        it_behaves_like 'does not an create alert management alert'
      end
    end
  end
end
