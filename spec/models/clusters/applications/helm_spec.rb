# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Helm do
  include_examples 'cluster application core specs', :clusters_applications_helm

  describe '.available' do
    subject { described_class.available }

    let!(:installed_cluster) { create(:clusters_applications_helm, :installed) }
    let!(:updated_cluster) { create(:clusters_applications_helm, :updated) }

    before do
      create(:clusters_applications_helm, :errored)
    end

    it { is_expected.to contain_exactly(installed_cluster, updated_cluster) }
  end

  describe '#can_uninstall?' do
    context "with other existing applications" do
      Clusters::Cluster::APPLICATIONS.keys.each do |application_name|
        next if application_name == 'helm'

        it "is false when #{application_name} is installed" do
          cluster_application = create("clusters_applications_#{application_name}".to_sym)

          helm = cluster_application.cluster.application_helm

          expect(helm.allowed_to_uninstall?).to be_falsy
        end
      end

      it 'executes a single query only' do
        cluster_application = create(:clusters_applications_ingress)
        helm = cluster_application.cluster.application_helm

        query_count = ActiveRecord::QueryRecorder.new { helm.allowed_to_uninstall? }.count
        expect(query_count).to eq(1)
      end
    end

    context "without other existing applications" do
      subject { helm.can_uninstall? }

      let(:helm) { create(:clusters_applications_helm) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#issue_client_cert' do
    let(:application) { create(:clusters_applications_helm) }

    subject { application.issue_client_cert }

    it 'returns a new cert' do
      is_expected.to be_kind_of(Gitlab::Kubernetes::Helm::Certificate)
      expect(subject.cert_string).not_to eq(application.ca_cert)
      expect(subject.key_string).not_to eq(application.ca_key)
    end
  end

  describe '#install_command' do
    let(:helm) { create(:clusters_applications_helm) }

    subject { helm.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InitCommand) }

    it 'is initialized with 1 arguments' do
      expect(subject.name).to eq('helm')
    end

    it 'has cert files' do
      expect(subject.files[:'ca.pem']).to be_present
      expect(subject.files[:'ca.pem']).to eq(helm.ca_cert)

      expect(subject.files[:'cert.pem']).to be_present
      expect(subject.files[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject.files[:'cert.pem'])
      expect(cert.not_after).to be > 999.years.from_now
    end

    describe 'rbac' do
      context 'rbac cluster' do
        it { expect(subject).to be_rbac }
      end

      context 'non rbac cluster' do
        before do
          helm.cluster.platform_kubernetes.abac!
        end

        it { expect(subject).not_to be_rbac }
      end
    end
  end

  describe '#uninstall_command' do
    let(:helm) { create(:clusters_applications_helm) }

    subject { helm.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::ResetCommand) }

    it 'has name' do
      expect(subject.name).to eq('helm')
    end

    it 'has cert files' do
      expect(subject.files[:'ca.pem']).to be_present
      expect(subject.files[:'ca.pem']).to eq(helm.ca_cert)

      expect(subject.files[:'cert.pem']).to be_present
      expect(subject.files[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject.files[:'cert.pem'])
      expect(cert.not_after).to be > 999.years.from_now
    end

    describe 'rbac' do
      context 'rbac cluster' do
        it { expect(subject).to be_rbac }
      end

      context 'non rbac cluster' do
        before do
          helm.cluster.platform_kubernetes.abac!
        end

        it { expect(subject).not_to be_rbac }
      end
    end
  end

  describe '#post_uninstall' do
    let(:helm) { create(:clusters_applications_helm, :installed) }

    it do
      expect(helm.cluster.kubeclient).to receive(:delete_namespace).with('gitlab-managed-apps')

      helm.post_uninstall
    end
  end
end
