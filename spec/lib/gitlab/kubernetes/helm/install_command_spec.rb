# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InstallCommand do
  let(:files) { { 'ca.pem': 'some file content' } }
  let(:repository) { 'https://repository.example.com' }
  let(:rbac) { false }
  let(:version) { '1.2.3' }
  let(:preinstall) { nil }
  let(:postinstall) { nil }

  let(:install_command) do
    described_class.new(
      name: 'app-name',
      chart: 'chart-name',
      rbac: rbac,
      files: files,
      version: version,
      repository: repository,
      preinstall: preinstall,
      postinstall: postinstall
    )
  end

  let(:tls_flags) do
    <<~EOS.squish
    --tls
    --tls-ca-cert /data/helm/app-name/config/ca.pem
    --tls-cert /data/helm/app-name/config/cert.pem
    --tls-key /data/helm/app-name/config/key.pem
    EOS
  end

  subject { install_command }

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
      helm init --upgrade
      for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
      helm repo add app-name https://repository.example.com
      helm repo update
      #{helm_install_comand}
      EOS
    end

    let(:helm_install_comand) do
      <<~EOS.squish
      helm upgrade app-name chart-name
        --install
        --reset-values
        #{tls_flags}
        --version 1.2.3
        --set rbac.create\\=false,rbac.enabled\\=false
        --namespace gitlab-managed-apps
        -f /data/helm/app-name/config/values.yaml
      EOS
    end
  end

  context 'when rbac is true' do
    let(:rbac) { true }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --reset-values
          #{tls_flags}
          --version 1.2.3
          --set rbac.create\\=true,rbac.enabled\\=true
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is a pre-install script' do
    let(:preinstall) { ['/bin/date', '/bin/true'] }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm repo add app-name https://repository.example.com
        helm repo update
        /bin/date
        /bin/true
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --reset-values
          #{tls_flags}
          --version 1.2.3
          --set rbac.create\\=false,rbac.enabled\\=false
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is a post-install script' do
    let(:postinstall) { ['/bin/date', "/bin/false\n"] }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        /bin/date
        /bin/false
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --reset-values
          #{tls_flags}
          --version 1.2.3
          --set rbac.create\\=false,rbac.enabled\\=false
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is no ca.pem file' do
    let(:files) { { 'file.txt': 'some content' } }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
           --install
           --reset-values
           --version 1.2.3
           --set rbac.create\\=false,rbac.enabled\\=false
           --namespace gitlab-managed-apps
           -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is no version' do
    let(:version) { nil }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_install_command}
        EOS
      end

      let(:helm_install_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --install
          --reset-values
          #{tls_flags}
          --set rbac.create\\=false,rbac.enabled\\=false
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  describe '#rbac?' do
    subject { install_command.rbac? }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it { is_expected.to be_truthy }
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#pod_resource' do
    subject { install_command.pod_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a pod that uses the tiller serviceAccountName' do
        expect(subject.spec.serviceAccountName).to eq('tiller')
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it 'generates a pod that uses the default serviceAccountName' do
        expect(subject.spec.serviceAcccountName).to be_nil
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

  describe '#service_account_resource' do
    subject { install_command.service_account_resource }

    it 'returns nothing' do
      is_expected.to be_nil
    end
  end

  describe '#cluster_role_binding_resource' do
    subject { install_command.cluster_role_binding_resource }

    it 'returns nothing' do
      is_expected.to be_nil
    end
  end
end
