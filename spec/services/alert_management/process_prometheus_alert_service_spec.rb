# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::ProcessPrometheusAlertService do
  let_it_be(:project, reload: true) { create(:project, :repository) }

  before do
    allow(ProjectServiceWorker).to receive(:perform_async)
  end

  describe '#execute' do
    let(:service) { described_class.new(project, nil, payload) }
    let(:auto_close_incident) { true }
    let(:create_issue) { true }
    let(:send_email) { true }
    let(:incident_management_setting) do
      double(
        auto_close_incident?: auto_close_incident,
        create_issue?: create_issue,
        send_email?: send_email
      )
    end

    before do
      allow(service)
        .to receive(:incident_management_setting)
        .and_return(incident_management_setting)
    end

    subject(:execute) { service.execute }

    context 'when alert payload is valid' do
      let(:parsed_payload) { Gitlab::AlertManagement::Payload.parse(project, payload, monitoring_tool: 'Prometheus') }
      let(:fingerprint) { parsed_payload.gitlab_fingerprint }
      let(:payload) do
        {
          'status' => status,
          'labels' => {
            'alertname' => 'GitalyFileServerDown',
            'channel' => 'gitaly',
            'pager' => 'pagerduty',
            'severity' => 's1'
          },
          'annotations' => {
            'description' => 'Alert description',
            'runbook' => 'troubleshooting/gitaly-down.md',
            'title' => 'Alert title'
          },
          'startsAt' => '2020-04-27T10:10:22.265949279Z',
          'endsAt' => '2020-04-27T10:20:22.265949279Z',
          'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1',
          'fingerprint' => 'b6ac4d42057c43c1'
        }
      end

      let(:status) { 'firing' }

      context 'when Prometheus alert status is firing' do
        context 'when alert with the same fingerprint already exists' do
          let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint) }

          it_behaves_like 'adds an alert management alert event'
          it_behaves_like 'processes incident issues'
          it_behaves_like 'Alert Notification Service sends notification email'

          context 'existing alert is resolved' do
            let!(:alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: fingerprint) }

            it_behaves_like 'creates an alert management alert'
          end

          context 'existing alert is ignored' do
            let!(:alert) { create(:alert_management_alert, :ignored, project: project, fingerprint: fingerprint) }

            it_behaves_like 'adds an alert management alert event'
          end

          context 'two existing alerts, one resolved one open' do
            let!(:resolved_alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: fingerprint) }
            let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint) }

            it_behaves_like 'adds an alert management alert event'
          end

          context 'when status change did not succeed' do
            before do
              allow(AlertManagement::Alert).to receive(:for_fingerprint).and_return([alert])
              allow(alert).to receive(:trigger).and_return(false)
            end

            it 'writes a warning to the log' do
              expect(Gitlab::AppLogger).to receive(:warn).with(
                message: 'Unable to update AlertManagement::Alert status to triggered',
                project_id: project.id,
                alert_id: alert.id
              )

              execute
            end
          end

          context 'when auto-creation of issues is disabled' do
            let(:create_issue) { false }

            it_behaves_like 'does not process incident issues'
          end

          context 'when emails are disabled' do
            let(:send_email) { false }

            it 'does not send notification' do
              expect(NotificationService).not_to receive(:new)

              expect(subject).to be_success
            end
          end
        end

        context 'when alert does not exist' do
          context 'when alert can be created' do
            it_behaves_like 'creates an alert management alert'
            it_behaves_like 'Alert Notification Service sends notification email'
            it_behaves_like 'processes incident issues'

            it 'creates a system note corresponding to alert creation' do
              expect { subject }.to change(Note, :count).by(1)
            end

            context 'when auto-alert creation is disabled' do
              let(:create_issue) { false }

              it_behaves_like 'does not process incident issues'
            end

            context 'when emails are disabled' do
              let(:send_email) { false }

              it 'does not send notification' do
                expect(NotificationService).not_to receive(:new)

                expect(subject).to be_success
              end
            end
          end

          context 'when alert cannot be created' do
            let(:errors) { double(messages: { hosts: ['hosts array is over 255 chars'] })}

            before do
              allow(service).to receive(:alert).and_call_original
              allow(service).to receive_message_chain(:alert, :save).and_return(false)
              allow(service).to receive_message_chain(:alert, :errors).and_return(errors)
            end

            it_behaves_like 'Alert Notification Service sends no notifications', http_status: :bad_request
            it_behaves_like 'does not process incident issues due to error', http_status: :bad_request

            it 'writes a warning to the log' do
              expect(Gitlab::AppLogger).to receive(:warn).with(
                message: 'Unable to create AlertManagement::Alert',
                project_id: project.id,
                alert_errors: { hosts: ['hosts array is over 255 chars'] }
              )

              execute
            end
          end

          it { is_expected.to be_success }
        end
      end

      context 'when Prometheus alert status is resolved' do
        let(:status) { 'resolved' }
        let!(:alert) { create(:alert_management_alert, project: project, fingerprint: fingerprint) }

        context 'when auto_resolve_incident set to true' do
          context 'when status can be changed' do
            it_behaves_like 'Alert Notification Service sends notification email'
            it_behaves_like 'does not process incident issues'

            it 'resolves an existing alert' do
              expect { execute }.to change { alert.reload.resolved? }.to(true)
            end

            context 'existing issue' do
              let!(:alert) { create(:alert_management_alert, :with_issue, project: project, fingerprint: fingerprint) }

              it 'closes the issue' do
                issue = alert.issue

                expect { execute }
                  .to change { issue.reload.state }
                  .from('opened')
                  .to('closed')
              end

              it 'creates a resource state event' do
                expect { execute }.to change(ResourceStateEvent, :count).by(1)
              end
            end
          end

          context 'when status change did not succeed' do
            before do
              allow(AlertManagement::Alert).to receive(:for_fingerprint).and_return([alert])
              allow(alert).to receive(:resolve).and_return(false)
            end

            it 'writes a warning to the log' do
              expect(Gitlab::AppLogger).to receive(:warn).with(
                message: 'Unable to update AlertManagement::Alert status to resolved',
                project_id: project.id,
                alert_id: alert.id
              )

              execute
            end

            it_behaves_like 'Alert Notification Service sends notification email'
          end

          it { is_expected.to be_success }
        end

        context 'when auto_resolve_incident set to false' do
          let(:auto_close_incident) { false }

          it 'does not resolve an existing alert' do
            expect { execute }.not_to change { alert.reload.resolved? }
          end
        end

        context 'when emails are disabled' do
          let(:send_email) { false }

          it 'does not send notification' do
            expect(NotificationService).not_to receive(:new)

            expect(subject).to be_success
          end
        end
      end

      context 'environment given' do
        let(:environment) { create(:environment, project: project) }

        it 'sets the environment' do
          payload['labels']['gitlab_environment_name'] = environment.name
          execute

          alert = project.alert_management_alerts.last

          expect(alert.environment).to eq(environment)
        end
      end

      context 'prometheus alert given' do
        let(:prometheus_alert) { create(:prometheus_alert, project: project) }

        it 'sets the prometheus alert and environment' do
          payload['labels']['gitlab_alert_id'] = prometheus_alert.prometheus_metric_id
          execute

          alert = project.alert_management_alerts.last

          expect(alert.prometheus_alert).to eq(prometheus_alert)
          expect(alert.environment).to eq(prometheus_alert.environment)
        end
      end
    end

    context 'when alert payload is invalid' do
      let(:payload) { {} }

      it 'responds with bad_request' do
        expect(execute).to be_error
        expect(execute.http_status).to eq(:bad_request)
      end
    end
  end
end
