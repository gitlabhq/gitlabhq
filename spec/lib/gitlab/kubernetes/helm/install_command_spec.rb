require 'rails_helper'

describe Gitlab::Kubernetes::Helm::InstallCommand do
  let(:application) { create(:clusters_applications_prometheus) }
  let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }

  let(:install_command) do
    described_class.new(
      application.name,
      chart: application.chart,
      values: application.values
    )
  end

  describe '#generate_script' do
    let(:command) do
      <<~MSG
      set -eo pipefail
      apk add -U ca-certificates openssl >/dev/null
      wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
      mv /tmp/linux-amd64/helm /usr/bin/
      helm init --client-only >/dev/null
      helm install #{application.chart} --name #{application.name} --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
      MSG
    end

    subject { install_command.generate_script }

    it 'should return appropriate command' do
      is_expected.to eq(command)
    end

    context 'with an application with a repository' do
      let(:ci_runner) { create(:ci_runner) }
      let(:application) { create(:clusters_applications_runner, runner: ci_runner) }
      let(:install_command) do
        described_class.new(
          application.name,
          chart: application.chart,
          values: application.values,
          repository: application.repository
        )
      end

      let(:command) do
        <<~MSG
        set -eo pipefail
        apk add -U ca-certificates openssl >/dev/null
        wget -q -O - https://kubernetes-helm.storage.googleapis.com/helm-v2.7.0-linux-amd64.tar.gz | tar zxC /tmp >/dev/null
        mv /tmp/linux-amd64/helm /usr/bin/
        helm init --client-only >/dev/null
        helm repo add #{application.name} #{application.repository}
        helm install #{application.chart} --name #{application.name} --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        MSG
      end

      it 'should return appropriate command' do
        is_expected.to eq(command)
      end
    end
  end

  describe '#config_map?' do
    subject { install_command.config_map? }

    it { is_expected.to be_truthy }
  end

  describe '#config_map_resource' do
    let(:metadata) do
      {
        name: "values-content-configuration-#{application.name}",
        namespace: namespace,
        labels: { name: "values-content-configuration-#{application.name}" }
      }
    end

    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: { values: application.values }) }

    subject { install_command.config_map_resource }

    it 'returns a KubeClient resource with config map content for the application' do
      is_expected.to eq(resource)
    end
  end
end
