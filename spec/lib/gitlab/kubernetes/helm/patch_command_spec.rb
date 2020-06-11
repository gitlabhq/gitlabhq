# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::PatchCommand do
  let(:files) { { 'ca.pem': 'some file content' } }
  let(:repository) { 'https://repository.example.com' }
  let(:rbac) { false }
  let(:version) { '1.2.3' }
  let(:local_tiller_enabled) { true }

  subject(:patch_command) do
    described_class.new(
      name: 'app-name',
      chart: 'chart-name',
      rbac: rbac,
      files: files,
      version: version,
      repository: repository,
      local_tiller_enabled: local_tiller_enabled
    )
  end

  context 'when local tiller feature is disabled' do
    let(:local_tiller_enabled) { false }

    let(:tls_flags) do
      <<~EOS.squish
      --tls
      --tls-ca-cert /data/helm/app-name/config/ca.pem
      --tls-cert /data/helm/app-name/config/cert.pem
      --tls-key /data/helm/app-name/config/key.pem
      EOS
    end

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_upgrade_comand}
        EOS
      end

      let(:helm_upgrade_comand) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --reuse-values
          #{tls_flags}
          --version 1.2.3
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  it_behaves_like 'helm command generator' do
    let(:commands) do
      <<~EOS
      export HELM_HOST="localhost:44134"
      tiller -listen ${HELM_HOST} -alsologtostderr &
      helm init --client-only
      helm repo add app-name https://repository.example.com
      helm repo update
      #{helm_upgrade_comand}
      EOS
    end

    let(:helm_upgrade_comand) do
      <<~EOS.squish
      helm upgrade app-name chart-name
        --reuse-values
        --version 1.2.3
        --namespace gitlab-managed-apps
        -f /data/helm/app-name/config/values.yaml
      EOS
    end
  end

  context 'when rbac is true' do
    let(:rbac) { true }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        export HELM_HOST="localhost:44134"
        tiller -listen ${HELM_HOST} -alsologtostderr &
        helm init --client-only
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_upgrade_command}
        EOS
      end

      let(:helm_upgrade_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
          --reuse-values
          --version 1.2.3
          --namespace gitlab-managed-apps
          -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is no ca.pem file' do
    let(:files) { { 'file.txt': 'some content' } }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        export HELM_HOST="localhost:44134"
        tiller -listen ${HELM_HOST} -alsologtostderr &
        helm init --client-only
        helm repo add app-name https://repository.example.com
        helm repo update
        #{helm_upgrade_command}
        EOS
      end

      let(:helm_upgrade_command) do
        <<~EOS.squish
        helm upgrade app-name chart-name
           --reuse-values
           --version 1.2.3
           --namespace gitlab-managed-apps
           -f /data/helm/app-name/config/values.yaml
        EOS
      end
    end
  end

  context 'when there is no version' do
    let(:version) { nil }

    it { expect { patch_command }.to raise_error(ArgumentError, 'version is required') }
  end

  describe '#pod_name' do
    subject { patch_command.pod_name }

    it { is_expected.to eq 'install-app-name' }
  end

  it_behaves_like 'helm command' do
    let(:command) { patch_command }
  end
end
