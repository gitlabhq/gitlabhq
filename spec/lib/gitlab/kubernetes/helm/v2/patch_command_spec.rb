# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::Helm::V2::PatchCommand do
  let(:files) { { 'ca.pem': 'some file content' } }
  let(:repository) { 'https://repository.example.com' }
  let(:rbac) { false }
  let(:version) { '1.2.3' }

  subject(:patch_command) do
    described_class.new(
      name: 'app-name',
      chart: 'chart-name',
      rbac: rbac,
      files: files,
      version: version,
      repository: repository
    )
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
