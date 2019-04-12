# frozen_string_literal: true

require 'rails_helper'

describe Clusters::Applications::CertManager do
  let(:cert_manager) { create(:clusters_applications_cert_managers) }

  include_examples 'cluster application core specs', :clusters_applications_cert_managers
  include_examples 'cluster application status specs', :clusters_applications_cert_managers
  include_examples 'cluster application version specs', :clusters_applications_cert_managers
  include_examples 'cluster application initial status specs'

  describe '#can_uninstall?' do
    subject { cert_manager.can_uninstall? }

    it { is_expected.to be_falsey }
  end

  describe '#install_command' do
    let(:cert_email) { 'admin@example.com' }

    let(:cluster_issuer_file) do
      file_contents = <<~EOF
      ---
      apiVersion: certmanager.k8s.io/v1alpha1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: #{cert_email}
          privateKeySecretRef:
            name: letsencrypt-prod
          http01: {}
      EOF

      { "cluster_issuer.yaml": file_contents }
    end

    subject { cert_manager.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with cert_manager arguments' do
      expect(subject.name).to eq('certmanager')
      expect(subject.chart).to eq('stable/cert-manager')
      expect(subject.version).to eq('v0.5.2')
      expect(subject).to be_rbac
      expect(subject.files).to eq(cert_manager.files.merge(cluster_issuer_file))
      expect(subject.postinstall).to eq(['/usr/bin/kubectl create -f /data/helm/certmanager/config/cluster_issuer.yaml'])
    end

    context 'for a specific user' do
      let(:cert_email) { 'abc@xyz.com' }

      before do
        cert_manager.email = cert_email
      end

      it 'uses his/her email to register issuer with certificate provider' do
        expect(subject.files).to eq(cert_manager.files.merge(cluster_issuer_file))
      end
    end

    context 'on a non rbac enabled cluster' do
      before do
        cert_manager.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:cert_manager) { create(:clusters_applications_cert_managers, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('v0.5.2')
      end
    end
  end

  describe '#files' do
    let(:application) { cert_manager }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes cert_manager specific keys in the values.yaml file' do
      expect(values).to include('ingressShim')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
  end
end
