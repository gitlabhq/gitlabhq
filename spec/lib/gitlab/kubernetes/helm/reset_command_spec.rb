# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::ResetCommand do
  subject(:reset_command) { described_class.new(name: name, rbac: rbac, files: files, local_tiller_enabled: false) }

  let(:rbac) { true }
  let(:name) { 'helm' }
  let(:files) { {} }

  it_behaves_like 'helm command generator' do
    let(:commands) do
      <<~EOS
      helm reset
      kubectl delete replicaset -n gitlab-managed-apps -l name\\=tiller
      kubectl delete clusterrolebinding tiller-admin
      EOS
    end
  end

  context 'when there is a ca.pem file' do
    let(:files) { { 'ca.pem': 'some file content' } }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS1.squish + "\n" + <<~EOS2
        helm reset
        --tls
        --tls-ca-cert /data/helm/helm/config/ca.pem
        --tls-cert /data/helm/helm/config/cert.pem
        --tls-key /data/helm/helm/config/key.pem
        EOS1
          kubectl delete replicaset -n gitlab-managed-apps -l name\\=tiller
          kubectl delete clusterrolebinding tiller-admin
        EOS2
      end
    end
  end

  describe '#pod_name' do
    subject { reset_command.pod_name }

    it { is_expected.to eq('uninstall-helm') }
  end

  it_behaves_like 'helm command' do
    let(:command) { reset_command }
  end
end
