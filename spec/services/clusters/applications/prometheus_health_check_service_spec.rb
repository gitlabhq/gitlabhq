# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::PrometheusHealthCheckService, '#execute' do
  let(:service) { described_class.new(cluster) }

  subject { service.execute }

  RSpec.shared_examples 'no alert' do
    it 'does not send alert' do
      expect(Projects::Alerting::NotifyService).not_to receive(:new)

      subject
    end
  end

  RSpec.shared_examples 'sends alert' do
    it 'sends an alert' do
      expect_next_instance_of(Projects::Alerting::NotifyService) do |notify_service|
        expect(notify_service).to receive(:execute).with(integration.token, integration)
      end

      subject
    end
  end

  RSpec.shared_examples 'correct health stored' do
    it 'stores the correct health of prometheus app' do
      subject

      expect(prometheus.healthy).to eq(client_healthy)
    end
  end

  context 'when cluster is not project_type' do
    let(:cluster) { create(:cluster, :instance) }

    it { expect { subject }.to raise_error(RuntimeError, 'Invalid cluster type. Only project types are allowed.') }
  end

  context 'when cluster is project_type' do
    let_it_be(:project) { create(:project) }
    let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

    let(:applications_prometheus_healthy) { true }
    let(:prometheus) { create(:clusters_applications_prometheus, status: prometheus_status_value, healthy: applications_prometheus_healthy) }
    let(:cluster) { create(:cluster, :project, application_prometheus: prometheus, projects: [project]) }

    context 'when prometheus not installed' do
      let(:prometheus_status_value) { Clusters::Applications::Prometheus.state_machine.states[:installing].value }

      it { expect(subject).to eq(nil) }
      include_examples 'no alert'
    end

    context 'when prometheus installed' do
      let(:prometheus_status_value) { Clusters::Applications::Prometheus.state_machine.states[:installed].value }

      before do
        client = instance_double('PrometheusClient', healthy?: client_healthy)
        expect(prometheus).to receive(:prometheus_client).and_return(client)
      end

      context 'when newly unhealthy' do
        let(:applications_prometheus_healthy) { true }
        let(:client_healthy) { false }

        include_examples 'sends alert'
        include_examples 'correct health stored'
      end

      context 'when newly healthy' do
        let(:applications_prometheus_healthy) { false }
        let(:client_healthy) { true }

        include_examples 'no alert'
        include_examples 'correct health stored'
      end

      context 'when continuously unhealthy' do
        let(:applications_prometheus_healthy) { false }
        let(:client_healthy) { false }

        include_examples 'no alert'
        include_examples 'correct health stored'
      end

      context 'when continuously healthy' do
        let(:applications_prometheus_healthy) { true }
        let(:client_healthy) { true }

        include_examples 'no alert'
        include_examples 'correct health stored'
      end

      context 'when first health check and healthy' do
        let(:applications_prometheus_healthy) { nil }
        let(:client_healthy) { true }

        include_examples 'no alert'
        include_examples 'correct health stored'
      end

      context 'when first health check and not healthy' do
        let(:applications_prometheus_healthy) { nil }
        let(:client_healthy) { false }

        include_examples 'sends alert'
        include_examples 'correct health stored'
      end
    end
  end
end
