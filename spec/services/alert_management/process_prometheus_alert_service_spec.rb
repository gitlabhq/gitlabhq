# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::ProcessPrometheusAlertService do
  let_it_be(:project) { create(:project) }

  describe '#execute' do
    subject(:execute) { described_class.new(project, nil, payload).execute }

    context 'when alert payload is valid' do
      let(:parsed_alert) { Gitlab::Alerting::Alert.new(project: project, payload: payload) }
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

      context 'when Prometheus alert status is firing' do
        let(:status) { 'firing' }

        context 'when alert with the same fingerprint already exists' do
          let!(:alert) { create(:alert_management_alert, :resolved, project: project, fingerprint: parsed_alert.gitlab_fingerprint) }

          it 'increases alert events count' do
            expect { execute }.to change { alert.reload.events }.by(1)
          end

          context 'when status can be changed' do
            it 'changes status to triggered' do
              expect { execute }.to change { alert.reload.triggered? }.to(true)
            end
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

          it { is_expected.to be_success }
        end

        context 'when alert does not exist' do
          context 'when alert can be created' do
            it 'creates a new alert' do
              expect { execute }.to change { AlertManagement::Alert.where(project: project).count }.by(1)
            end
          end

          context 'when alert cannot be created' do
            let(:errors) { double(messages: { hosts: ['hosts array is over 255 chars'] })}
            let(:am_alert) { instance_double(AlertManagement::Alert, save: false, errors: errors) }

            before do
              allow(AlertManagement::Alert).to receive(:new).and_return(am_alert)
            end

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
        let!(:alert) { create(:alert_management_alert, project: project, fingerprint: parsed_alert.gitlab_fingerprint) }

        context 'when status can be changed' do
          it 'resolves an existing alert' do
            expect { execute }.to change { alert.reload.resolved? }.to(true)
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
        end

        it { is_expected.to be_success }
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
