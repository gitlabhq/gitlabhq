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
    let(:starts_at) { Time.now.change(usec: 0) }
    let(:service) { described_class.new(project, nil, payload) }
    let(:payload_raw) do
      {
        'title' => 'alert title',
        'start_time' => starts_at.rfc3339
      }
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
          it 'creates AlertManagement::Alert' do
            expect { subject }.to change(AlertManagement::Alert, :count).by(1)
          end

          it 'created alert has all data properly assigned' do
            subject

            alert = AlertManagement::Alert.last
            alert_attributes = alert.attributes.except('id', 'iid', 'created_at', 'updated_at')

            expect(alert_attributes).to eq(
              'project_id' => project.id,
              'issue_id' => nil,
              'fingerprint' => nil,
              'title' => 'alert title',
              'description' => nil,
              'monitoring_tool' => nil,
              'service' => nil,
              'hosts' => [],
              'payload' => payload_raw,
              'severity' => 'critical',
              'status' => AlertManagement::Alert::STATUSES[:triggered],
              'events' => 1,
              'started_at' => alert.started_at,
              'ended_at' => nil
            )
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
