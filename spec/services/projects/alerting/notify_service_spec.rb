# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Alerting::NotifyService do
  let_it_be_with_reload(:project) { create(:project, :repository) }

  before do
    allow(ProjectServiceWorker).to receive(:perform_async)
  end

  describe '#execute' do
    let(:token) { 'invalid-token' }
    let(:starts_at) { Time.current.change(usec: 0) }
    let(:fingerprint) { 'testing' }
    let(:service) { described_class.new(project, nil, payload) }
    let_it_be(:environment) { create(:environment, project: project) }
    let(:environment) { create(:environment, project: project) }
    let(:ended_at) { nil }
    let(:payload_raw) do
      {
        title: 'alert title',
        start_time: starts_at.rfc3339,
        end_time: ended_at&.rfc3339,
        severity: 'low',
        monitoring_tool: 'GitLab RSpec',
        service: 'GitLab Test Suite',
        description: 'Very detailed description',
        hosts: ['1.1.1.1', '2.2.2.2'],
        fingerprint: fingerprint,
        gitlab_environment_name: environment.name
      }.with_indifferent_access
    end

    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }

    subject { service.execute(token, nil) }

    shared_examples 'notifcations are handled correctly' do
      context 'with valid token' do
        let(:token) { integration.token }
        let(:incident_management_setting) { double(send_email?: email_enabled, create_issue?: issue_enabled, auto_close_incident?: auto_close_enabled) }
        let(:email_enabled) { false }
        let(:issue_enabled) { false }
        let(:auto_close_enabled) { false }

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
                status: AlertManagement::Alert.status_value(:triggered),
                events: 1,
                hosts: payload_raw.fetch(:hosts),
                payload: payload_raw.with_indifferent_access,
                issue_id: nil,
                description: payload_raw.fetch(:description),
                monitoring_tool: payload_raw.fetch(:monitoring_tool),
                service: payload_raw.fetch(:service),
                fingerprint: Digest::SHA1.hexdigest(fingerprint),
                environment_id: environment.id,
                ended_at: nil,
                prometheus_alert_id: nil
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

          it 'creates a system note corresponding to alert creation' do
            expect { subject }.to change(Note, :count).by(1)
            expect(Note.last.note).to include(payload_raw.fetch(:monitoring_tool))
          end

          context 'existing alert with same fingerprint' do
            let(:fingerprint_sha) { Digest::SHA1.hexdigest(fingerprint) }
            let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint_sha) }

            it_behaves_like 'adds an alert management alert event'

            context 'end time given' do
              let(:ended_at) { Time.current.change(nsec: 0) }

              it 'does not resolve the alert' do
                expect { subject }.not_to change { alert.reload.status }
              end

              it 'does not set the ended at' do
                subject

                expect(alert.reload.ended_at).to be_nil
              end

              it_behaves_like 'does not an create alert management alert'

              context 'auto_close_enabled setting enabled' do
                let(:auto_close_enabled) { true }

                it 'resolves the alert and sets the end time', :aggregate_failures do
                  subject
                  alert.reload

                  expect(alert.resolved?).to eq(true)
                  expect(alert.ended_at).to eql(ended_at)
                end

                context 'related issue exists' do
                  let(:alert) { create(:alert_management_alert, :with_issue, project: project, fingerprint: fingerprint_sha) }
                  let(:issue) { alert.issue }

                  it { expect { subject }.to change { issue.reload.state }.from('opened').to('closed') }
                  it { expect { subject }.to change(ResourceStateEvent, :count).by(1) }
                end

                context 'with issue enabled' do
                  let(:issue_enabled) { true }

                  it_behaves_like 'does not process incident issues'
                end
              end
            end

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

          context 'end time given' do
            let(:ended_at) { Time.current }

            it_behaves_like 'creates an alert management alert'
            it_behaves_like 'assigns the alert properties'
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
                status: AlertManagement::Alert.status_value(:triggered),
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

            it 'creates a system note corresponding to alert creation' do
              expect { subject }.to change(Note, :count).by(1)
              expect(Note.last.note).to include(source)
            end
          end
        end

        context 'with overlong payload' do
          let(:deep_size_object) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

          before do
            allow(Gitlab::Utils::DeepSize).to receive(:new).and_return(deep_size_object)
          end

          it_behaves_like 'does not process incident issues due to error', http_status: :bad_request
          it_behaves_like 'does not an create alert management alert'
        end

        it_behaves_like 'does not process incident issues'

        context 'issue enabled' do
          let(:issue_enabled) { true }

          it_behaves_like 'processes incident issues'

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

          it_behaves_like 'Alert Notification Service sends notification email'
        end
      end

      context 'with invalid token' do
        it_behaves_like 'does not process incident issues due to error', http_status: :unauthorized
        it_behaves_like 'does not an create alert management alert'
      end
    end

    context 'with an HTTP Integration' do
      let_it_be_with_reload(:integration) { create(:alert_management_http_integration, project: project) }

      subject { service.execute(token, integration) }

      it_behaves_like 'notifcations are handled correctly' do
        let(:source) { integration.name }
      end

      context 'with deactivated HTTP Integration' do
        before do
          integration.update!(active: false)
        end

        it_behaves_like 'does not process incident issues due to error', http_status: :forbidden
        it_behaves_like 'does not an create alert management alert'
      end
    end
  end
end
