# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CertManager do
  let(:cert_manager) { create(:clusters_applications_cert_manager) }

  include_examples 'cluster application core specs', :clusters_applications_cert_manager
  include_examples 'cluster application status specs', :clusters_applications_cert_manager
  include_examples 'cluster application version specs', :clusters_applications_cert_manager
  include_examples 'cluster application initial status specs'

  describe '#can_uninstall?' do
    subject { cert_manager.can_uninstall? }

    it { is_expected.to be_truthy }
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
      expect(subject.postinstall).to eq(['kubectl create -f /data/helm/certmanager/config/cluster_issuer.yaml'])
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
      let(:cert_manager) { create(:clusters_applications_cert_manager, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('v0.5.2')
      end
    end
  end

  describe '#uninstall_command' do
    subject { cert_manager.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

    it 'is initialized with cert_manager arguments' do
      expect(subject.name).to eq('certmanager')
      expect(subject).to be_rbac
      expect(subject.files).to eq(cert_manager.files)
    end

    it 'specifies a post delete command to remove custom resource definitions' do
      expect(subject.postdelete).to eq([
        "kubectl delete secret -n gitlab-managed-apps letsencrypt-prod --ignore-not-found",
        'kubectl delete crd certificates.certmanager.k8s.io --ignore-not-found',
        'kubectl delete crd clusterissuers.certmanager.k8s.io --ignore-not-found',
        'kubectl delete crd issuers.certmanager.k8s.io --ignore-not-found'
      ])
    end

    context 'secret key name is not found' do
      before do
        allow(File).to receive(:read).and_call_original
        expect(File).to receive(:read)
          .with(Rails.root.join('vendor', 'cert_manager', 'cluster_issuer.yaml'))
          .and_return('key: value')
      end

      it 'does not try and delete the secret' do
        expect(subject.postdelete).to eq([
          'kubectl delete crd certificates.certmanager.k8s.io --ignore-not-found',
          'kubectl delete crd clusterissuers.certmanager.k8s.io --ignore-not-found',
          'kubectl delete crd issuers.certmanager.k8s.io --ignore-not-found'
        ])
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
