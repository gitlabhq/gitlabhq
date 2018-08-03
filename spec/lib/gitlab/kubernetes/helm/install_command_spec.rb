require 'rails_helper'

describe Gitlab::Kubernetes::Helm::InstallCommand do
  let(:application) { create(:clusters_applications_prometheus) }
  let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }
  let(:install_command) { application.install_command }

  subject { install_command }

  context 'for ingress' do
    let(:application) { create(:clusters_applications_ingress) }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm install #{application.chart} --name #{application.name} --version #{application.version} --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'for prometheus' do
    let(:application) { create(:clusters_applications_prometheus) }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm install #{application.chart} --name #{application.name} --version #{application.version} --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'for runner' do
    let(:ci_runner) { create(:ci_runner) }
    let(:application) { create(:clusters_applications_runner, runner: ci_runner) }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm repo add #{application.name} #{application.repository}
         helm install #{application.chart} --name #{application.name} --version #{application.version} --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'for jupyter' do
    let(:application) { create(:clusters_applications_jupyter) }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm repo add #{application.name} #{application.repository}
         helm install #{application.chart} --name #{application.name} --version #{application.version} --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
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
