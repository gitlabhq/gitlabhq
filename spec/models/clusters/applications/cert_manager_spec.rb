require 'rails_helper'

describe Clusters::Applications::CertManager do
  let(:cert_manager) { create(:clusters_applications_cert_managers) }

  include_examples 'cluster application core specs', :clusters_applications_cert_managers
  include_examples 'cluster application status specs', :clusters_applications_cert_managers
  include_examples 'cluster application version specs', :clusters_applications_cert_managers
  include_examples 'cluster application initial status specs'

  describe '#install_command' do
    let(:cluster_issuer_file) { { "cluster_issuer.yaml": "---\napiVersion: certmanager.k8s.io/v1alpha1\nkind: ClusterIssuer\nmetadata:\n  name: letsencrypt-prod\nspec:\n  acme:\n    server: https://acme-v02.api.letsencrypt.org/directory\n    email: admin@example.com\n    privateKeySecretRef:\n      name: letsencrypt-prod\n    http01: {}\n" } }
    subject { cert_manager.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with cert_manager arguments' do
      expect(subject.name).to eq('certmanager')
      expect(subject.chart).to eq('stable/cert-manager')
      expect(subject.version).to eq('v0.5.2')
      expect(subject).to be_rbac
      expect(subject.files).to eq(cert_manager.files.merge(cluster_issuer_file))
      expect(subject.postinstall).to eq(['/usr/bin/kubectl create -f /data/helm/certmanager/config/cluster_issuer.yaml'])
    end

    context 'for a specific user' do
      before do
        cert_manager.email = 'abc@xyz.com'
        cluster_issuer_file[:'cluster_issuer.yaml'].gsub! 'admin@example.com', 'abc@xyz.com'
      end

      it 'should use his/her email to register issuer with certificate provider' do
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

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('v0.5.2')
      end
    end
  end

  describe '#files' do
    let(:application) { cert_manager }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include cert_manager specific keys in the values.yaml file' do
      expect(values).to include('ingressShim')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
  end
end
