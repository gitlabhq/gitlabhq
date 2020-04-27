# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  subject(:init_command) { described_class.new(name: application.name, files: files, rbac: rbac) }

  let(:application) { create(:clusters_applications_helm) }
  let(:rbac) { false }
  let(:files) { {} }

  it_behaves_like 'helm command generator' do
    let(:commands) do
      <<~EOS
      helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem
      EOS
    end
  end

  context 'on a rbac-enabled cluster' do
    let(:rbac) { true }

    it_behaves_like 'helm command generator' do
      let(:commands) do
        <<~EOS
        helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem --service-account tiller
        EOS
      end
    end
  end

  it_behaves_like 'helm command' do
    let(:command) { init_command }
  end
end
