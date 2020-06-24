# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::PrometheusConfigService do
  include Gitlab::Routing.url_helpers

  let_it_be(:project) { create(:project) }
  let_it_be(:production) { create(:environment, project: project) }
  let_it_be(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }

  let(:application) do
    create(:clusters_applications_prometheus, :installed, cluster: cluster)
  end

  subject { described_class.new(project, cluster, application).execute(input) }

  describe '#execute' do
    let(:input) do
      YAML.load_file(Rails.root.join('vendor/prometheus/values.yaml'))
    end

    context 'with alerts' do
      let!(:alert) do
        create(:prometheus_alert, project: project, environment: production)
      end

      it 'enables alertmanager' do
        expect(subject.dig('alertmanager', 'enabled')).to eq(true)
      end

      describe 'alertmanagerFiles' do
        let(:alertmanager) do
          subject.dig('alertmanagerFiles', 'alertmanager.yml')
        end

        it 'contains receivers and route' do
          expect(alertmanager.keys).to contain_exactly('receivers', 'route')
        end

        describe 'receivers' do
          let(:receiver) { alertmanager.dig('receivers', 0) }
          let(:webhook_config) { receiver.dig('webhook_configs', 0) }

          let(:notify_url) do
            notify_project_prometheus_alerts_url(project, format: :json)
          end

          it 'sets receiver' do
            expect(receiver['name']).to eq('gitlab')
          end

          it 'sets webhook_config' do
            expect(webhook_config).to eq(
              'url' => notify_url,
              'send_resolved' => true,
              'http_config' => {
                'bearer_token' => application.alert_manager_token
              }
            )
          end
        end

        describe 'route' do
          let(:route) { alertmanager.fetch('route') }

          it 'sets route' do
            expect(route).to eq(
              'receiver' => 'gitlab',
              'group_wait' => '30s',
              'group_interval' => '5m',
              'repeat_interval' => '4h'
            )
          end
        end
      end

      describe 'serverFiles' do
        let(:groups) { subject.dig('serverFiles', 'alerts', 'groups') }

        it 'sets the alerts' do
          rules = groups.dig(0, 'rules')
          expect(rules.size).to eq(1)

          expect(rules.first['alert']).to eq(alert.title)
        end

        context 'with parameterized queries' do
          let!(:alert) do
            create(:prometheus_alert,
                   project: project,
                   environment: production,
                   prometheus_metric: metric,
                   operator: PrometheusAlert.operators['gt'],
                   threshold: 0)
          end

          let(:metric) do
            create(:prometheus_metric, query: query, project: project)
          end

          let(:query) { 'up{environment="{{ci_environment_slug}}"}' }

          it 'substitutes query variables' do
            expect(Gitlab::Prometheus::QueryVariables)
              .to receive(:call)
              .with(production, start_time: nil, end_time: nil)
              .and_call_original

            expr = groups.dig(0, 'rules', 0, 'expr')
            expect(expr).to eq("up{environment=\"#{production.slug}\"} > 0.0")
          end
        end

        context 'with multiple environments' do
          let(:staging) { create(:environment, project: project) }

          before do
            create(:prometheus_alert, project: project, environment: production)
            create(:prometheus_alert, project: project, environment: staging)
          end

          it 'sets alerts for multiple environment' do
            env_names = groups.map { |group| group['name'] }
            expect(env_names).to contain_exactly(
              "#{production.name}.rules",
              "#{staging.name}.rules"
            )
          end

          it 'substitutes query variables once per environment' do
            allow(Gitlab::Prometheus::QueryVariables).to receive(:call).and_call_original

            expect(Gitlab::Prometheus::QueryVariables)
              .to receive(:call)
              .with(production, start_time: nil, end_time: nil)

            expect(Gitlab::Prometheus::QueryVariables)
              .to receive(:call)
              .with(staging, start_time: nil, end_time: nil)

            subject
          end
        end
      end
    end

    context 'without alerts' do
      it 'disables alertmanager' do
        expect(subject.dig('alertmanager', 'enabled')).to eq(false)
      end

      it 'removes alertmanagerFiles' do
        expect(subject).not_to include('alertmanagerFiles')
      end

      it 'removes alerts' do
        expect(subject.dig('serverFiles', 'alerts')).to eq({})
      end
    end
  end
end
