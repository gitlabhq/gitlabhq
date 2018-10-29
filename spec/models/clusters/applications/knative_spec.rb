require 'rails_helper'

describe Clusters::Applications::Knative do
  let(:knative) { create(:clusters_applications_knative) }

  include_examples 'cluster application core specs', :clusters_applications_knative
  include_examples 'cluster application status specs', :clusters_applications_knative

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_knative, :installed) }

    before do
      create(:clusters_applications_knative, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#make_installing!' do
    before do
      application.make_installing!
    end

    context 'application install previously errored with older version' do
      let(:application) { create(:clusters_applications_knative, :scheduled, version: '0.1.3') }

      it 'updates the application version' do
        expect(application.reload.version).to eq('0.1.3')
      end
    end
  end

  describe '#make_installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_knative, :installed) }

    before do
      create(:clusters_applications_knative, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#install_command' do
    subject { knative.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with knative arguments' do
      expect(subject.name).to eq('knative')
      expect(subject.chart).to eq('knative/knative')
      expect(subject.version).to eq('0.1.3')
      expect(subject.files).to eq(knative.files)
      expect(subject.setargs).to eq([])
    end

    context 'application failed to install previously' do
      let(:knative) { create(:clusters_applications_knative, :errored, version: 'knative') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('0.1.3')
      end
    end
  end

  describe '#files' do
    let(:application) { knative }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include knative valid keys in values' do
      expect(values).to include('domain')
    end

    context 'when the helm application does not have a ca_cert' do
      before do
        application.cluster.application_helm.ca_cert = nil
      end

      it 'should not include cert files' do
        expect(subject[:'ca.pem']).not_to be_present
        expect(subject[:'cert.pem']).not_to be_present
        expect(subject[:'key.pem']).not_to be_present
      end
    end

    it 'should include cert files' do
      expect(subject[:'ca.pem']).to be_present
      expect(subject[:'ca.pem']).to eq(application.cluster.application_helm.ca_cert)

      expect(subject[:'cert.pem']).to be_present
      expect(subject[:'key.pem']).to be_present

      cert = OpenSSL::X509::Certificate.new(subject[:'cert.pem'])
      expect(cert.not_after).to be < 60.minutes.from_now
    end
  end
end
