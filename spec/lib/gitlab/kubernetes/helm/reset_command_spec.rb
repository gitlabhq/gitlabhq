# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::ResetCommand do
  let(:rbac) { true }
  let(:name) { 'helm' }
  let(:files) { {} }
  let(:reset_command) { described_class.new(name: name, rbac: rbac, files: files) }

  subject { reset_command }

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
      helm reset
      kubectl delete replicaset -n gitlab-managed-apps -l name\\=tiller
      EOS
    end
  end

  context 'when there is a ca.pem file' do
    let(:files) { { 'ca.pem': 'some file content' } }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS1.squish + "\n" + <<~EOS2
        helm reset
        --tls
        --tls-ca-cert /data/helm/helm/config/ca.pem
        --tls-cert /data/helm/helm/config/cert.pem
        --tls-key /data/helm/helm/config/key.pem
        EOS1
          kubectl delete replicaset -n gitlab-managed-apps -l name\\=tiller
        EOS2
      end
    end
  end

  describe '#pod_resource' do
    subject { reset_command.pod_resource }

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

  describe '#pod_name' do
    subject { reset_command.pod_name }

    it { is_expected.to eq('uninstall-helm') }
  end
end
