# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::DeleteCommand do
  let(:app_name) { 'app-name' }
  let(:rbac) { true }
  let(:files) { {} }
  let(:delete_command) { described_class.new(name: app_name, rbac: rbac, files: files) }

  subject { delete_command }

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
      export HELM_HOST="localhost:44134"
      tiller -listen ${HELM_HOST} -alsologtostderr &
      helm init --client-only
      helm delete --purge app-name
      EOS
    end
  end

  context 'tillerless feature disabled' do
    before do
      stub_feature_flags(managed_apps_local_tiller: false)
    end

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --upgrade
        for i in $(seq 1 30); do helm version && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
        helm delete --purge app-name
        EOS
      end
    end

    context 'when there is a ca.pem file' do
      let(:files) { { 'ca.pem': 'some file content' } }

      let(:tls_flags) do
        <<~EOS.squish
        --tls
        --tls-ca-cert /data/helm/app-name/config/ca.pem
        --tls-cert /data/helm/app-name/config/cert.pem
        --tls-key /data/helm/app-name/config/key.pem
        EOS
      end

      it_behaves_like 'helm commands' do
        let(:commands) do
          <<~EOS
          helm init --upgrade
          for i in $(seq 1 30); do helm version #{tls_flags} && s=0 && break || s=$?; sleep 1s; echo \"Retrying ($i)...\"; done; (exit $s)
          #{helm_delete_command}
          EOS
        end

        let(:helm_delete_command) do
          <<~EOS.squish
          helm delete --purge app-name
          #{tls_flags}
          EOS
        end
      end
    end
  end

  describe '#pod_resource' do
    subject { delete_command.pod_resource }

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
    subject { delete_command.pod_name }

    it { is_expected.to eq('uninstall-app-name') }
  end
end
