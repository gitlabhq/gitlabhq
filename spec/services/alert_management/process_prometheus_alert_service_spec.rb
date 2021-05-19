# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::ProcessPrometheusAlertService do
  let_it_be(:project, reload: true) { create(:project, :repository) }

  let(:service) { described_class.new(project, payload) }

  describe '#execute' do
    include_context 'incident management settings enabled'

    subject(:execute) { service.execute }

    before do
      stub_licensed_features(oncall_schedules: false, generic_alert_fingerprinting: false)
    end

    context 'when alert payload is valid' do
      let_it_be(:starts_at) { '2020-04-27T10:10:22.265949279Z' }
      let_it_be(:title) { 'Alert title' }
      let_it_be(:fingerprint) { [starts_at, title, 'vector(1)'].join('/') }
      let_it_be(:source) { 'Prometheus' }

      let(:prometheus_status) { 'firing' }
      let(:payload) do
        {
          'status' => prometheus_status,
          'labels' => {
            'alertname' => 'GitalyFileServerDown',
            'channel' => 'gitaly',
            'pager' => 'pagerduty',
            'severity' => 's1'
          },
          'annotations' => {
            'description' => 'Alert description',
            'runbook' => 'troubleshooting/gitaly-down.md',
            'title' => title
          },
          'startsAt' => starts_at,
          'endsAt' => '2020-04-27T10:20:22.265949279Z',
          'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
        }
      end

      it_behaves_like 'processes new firing alert'

      context 'with resolving payload' do
        let(:prometheus_status) { 'resolved' }

        it_behaves_like 'processes recovery alert'
      end

      context 'environment given' do
        let(:environment) { create(:environment, project: project) }
        let(:alert) { project.alert_management_alerts.last }

        before do
          payload['labels']['gitlab_environment_name'] = environment.name
        end

        it 'sets the environment' do
          execute

          expect(alert.environment).to eq(environment)
        end
      end

      context 'prometheus alert given' do
        let(:prometheus_alert) { create(:prometheus_alert, project: project) }
        let(:alert) { project.alert_management_alerts.last }

        before do
          payload['labels']['gitlab_alert_id'] = prometheus_alert.prometheus_metric_id
        end

        it 'sets the prometheus alert and environment' do
          execute

          expect(alert.prometheus_alert).to eq(prometheus_alert)
          expect(alert.environment).to eq(prometheus_alert.environment)
        end
      end
    end

    context 'when alert payload is invalid' do
      let(:payload) { {} }

      it_behaves_like 'alerts service responds with an error and takes no actions', :bad_request
    end
  end
end
