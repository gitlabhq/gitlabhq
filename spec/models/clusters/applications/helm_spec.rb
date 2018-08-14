require 'rails_helper'

describe Clusters::Applications::Helm do
  include_examples 'cluster application core specs', :clusters_applications_helm

  describe '.installed' do
    subject { described_class.installed }

    let!(:installed_cluster) { create(:clusters_applications_helm, :installed) }

    before do
      create(:clusters_applications_helm, :errored)
    end

    it { is_expected.to contain_exactly(installed_cluster) }
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

    it 'should be initialized with 1 arguments' do
      expect(subject.name).to eq('helm')
    end

    it 'should have cert files' do
      expect(subject.files[:'ca.pem']).to be_present
      expect(subject.files[:'ca.pem']).to eq(helm.ca_cert)

      expect(subject.files[:'cert.pem']).to be_present
      expect(subject.files[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject.files[:'cert.pem'])
      expect(cert.not_after).to be > 999.years.from_now
    end
  end
end
