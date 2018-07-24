require 'rails_helper'

describe Gitlab::Kubernetes::Helm::InstallCommand do
  let(:files) { { 'ca.pem': 'some file content' } }
  let(:repository) { 'https://repository.example.com' }
  let(:version) { '1.2.3' }

  let(:install_command) do
    described_class.new(
      name: 'app-name',
      chart: 'chart-name',
      files: files,
      version: version, repository: repository
    )
  end

  subject { install_command }

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
      helm init --client-only >/dev/null
      helm repo add app-name https://repository.example.com
      helm install --tls --tls-ca-cert /data/helm/app-name/config/ca.pem --tls-cert /data/helm/app-name/config/cert.pem --tls-key /data/helm/app-name/config/key.pem chart-name --name app-name --version 1.2.3 --namespace gitlab-managed-apps -f /data/helm/app-name/config/values.yaml >/dev/null
      EOS
    end
  end

  context 'when there is no repository' do
    let(:repository) { nil }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm install --tls --tls-ca-cert /data/helm/app-name/config/ca.pem --tls-cert /data/helm/app-name/config/cert.pem --tls-key /data/helm/app-name/config/key.pem chart-name --name app-name --version 1.2.3 --namespace gitlab-managed-apps -f /data/helm/app-name/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'when there is no ca.pem file' do
    let(:files) { { 'file.txt': 'some content' } }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm repo add app-name https://repository.example.com
         helm install chart-name --name app-name --version 1.2.3 --namespace gitlab-managed-apps -f /data/helm/app-name/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  context 'when there is no version' do
    let(:version) { nil }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
         helm init --client-only >/dev/null
         helm repo add app-name https://repository.example.com
         helm install --tls --tls-ca-cert /data/helm/app-name/config/ca.pem --tls-cert /data/helm/app-name/config/cert.pem --tls-key /data/helm/app-name/config/key.pem chart-name --name app-name --namespace gitlab-managed-apps -f /data/helm/app-name/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  describe '#config_map_resource' do
    let(:metadata) do
      {
        name: "values-content-configuration-app-name",
        namespace: 'gitlab-managed-apps',
        labels: { name: "values-content-configuration-app-name" }
      }
    end

    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: files) }

    subject { install_command.config_map_resource }

    it 'returns a KubeClient resource with config map content for the application' do
      is_expected.to eq(resource)
    end
  end
end
