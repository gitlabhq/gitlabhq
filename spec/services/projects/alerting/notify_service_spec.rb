# frozen_string_literal: true

require 'spec_helper'

describe Projects::Alerting::NotifyService do
  let_it_be(:project, reload: true) { create(:project) }

  before do
    # We use `let_it_be(:project)` so we make sure to clear caches
    project.clear_memoization(:licensed_feature_available)
  end

  shared_examples 'processes incident issues' do |amount|
    let(:create_incident_service) { spy }
    let(:new_alert) { instance_double(AlertManagement::Alert, id: 503, persisted?: true) }

    it 'processes issues' do
      expect(AlertManagement::Alert)
        .to receive(:create)
        .and_return(new_alert)

      expect(IncidentManagement::ProcessAlertWorker)
        .to receive(:perform_async)
        .with(project.id, kind_of(Hash), new_alert.id)
        .exactly(amount).times

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

  shared_examples 'NotifyService does not create alert' do
    it 'does not create alert' do
      expect { subject }.not_to change(AlertManagement::Alert, :count)
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
          let(:last_alert_attributes) do
            AlertManagement::Alert.last.attributes
              .except('id', 'iid', 'created_at', 'updated_at')
              .with_indifferent_access
          end

          it 'creates AlertManagement::Alert' do
            expect { subject }.to change(AlertManagement::Alert, :count).by(1)
          end

          it 'created alert has all data properly assigned' do
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
              ended_at: nil
            )
          end

          context 'existing alert with same fingerprint' do
            let!(:existing_alert) { create(:alert_management_alert, project: project, fingerprint: Digest::SHA1.hexdigest(fingerprint)) }

            it 'does not create AlertManagement::Alert' do
              expect { subject }.not_to change(AlertManagement::Alert, :count)
            end

            it 'increments the existing alert count' do
              expect { subject }.to change { existing_alert.reload.events }.from(1).to(2)
            end
          end

          context 'with a minimal payload' do
            let(:payload_raw) do
              {
                title: 'alert title',
                start_time: starts_at.rfc3339
              }
            end

            it 'creates AlertManagement::Alert' do
              expect { subject }.to change(AlertManagement::Alert, :count).by(1)
            end

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
                ended_at: nil
              )
            end
          end
        end

        it_behaves_like 'does not process incident issues'

        context 'issue enabled' do
          let(:issue_enabled) { true }

          it_behaves_like 'processes incident issues', 1

          context 'with an invalid payload' do
            before do
              allow(Gitlab::Alerting::NotificationPayloadParser)
                .to receive(:call)
                .and_raise(Gitlab::Alerting::NotificationPayloadParser::BadPayloadError)
            end

            it_behaves_like 'does not process incident issues due to error', http_status: :bad_request
            it_behaves_like 'NotifyService does not create alert'
          end
        end

        context 'with emails turned on' do
          let(:email_enabled) { true }

          it_behaves_like 'sends notification email'
        end
      end

      context 'with invalid token' do
        it_behaves_like 'does not process incident issues due to error', http_status: :unauthorized
        it_behaves_like 'NotifyService does not create alert'
      end

      context 'with deactivated Alerts Service' do
        let!(:alerts_service) { create(:alerts_service, :inactive, project: project) }

        it_behaves_like 'does not process incident issues due to error', http_status: :forbidden
        it_behaves_like 'NotifyService does not create alert'
      end
    end
  end
end
