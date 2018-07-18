require 'rails_helper'

describe Clusters::Applications::Ingress do
  let(:ingress) { create(:clusters_applications_ingress) }

  include_examples 'cluster application core specs', :clusters_applications_ingress
  include_examples 'cluster application status specs', :cluster_application_ingress

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
  end

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_ingress, :installed) }

    before do
      create(:clusters_applications_ingress, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '#make_installing!' do
    before do
      application.make_installing!
    end

    context 'application install previously errored with older version' do
      let(:application) { create(:clusters_applications_ingress, :scheduled, version: '0.22.0') }

      it 'updates the application version' do
        expect(application.reload.version).to eq('0.23.0')
      end
    end
  end

  describe '#make_installed!' do
    before do
      application.make_installed!
    end

    let(:application) { create(:clusters_applications_ingress, :installing) }

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_in)
        .with(Clusters::Applications::Ingress::FETCH_IP_ADDRESS_DELAY, 'ingress', application.id)
    end
  end

  describe '#schedule_status_update' do
    let(:application) { create(:clusters_applications_ingress, :installed) }

    before do
      application.schedule_status_update
    end

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_async)
        .with('ingress', application.id)
    end

    context 'when the application is not installed' do
      let(:application) { create(:clusters_applications_ingress, :installing) }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_async)
      end
    end

    context 'when there is already an external_ip' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_ip: '111.222.222.111') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  describe '#derived_domain' do
    subject { ingress.derived_domain }

    it { is_expected.to be_nil }

    context 'when there is an external_ip' do
      let(:ingress) { create(:clusters_applications_ingress, external_ip: '127.0.0.1') }

      it { is_expected.to eq('127.0.0.1.nip.io') }
    end
  end

  describe '#install_command' do
    subject { ingress.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with ingress arguments' do
      expect(subject.name).to eq('ingress')
      expect(subject.chart).to eq('stable/nginx-ingress')
      expect(subject.version).to eq('0.23.0')
      expect(subject.files).to eq(ingress.files)
    end

    context 'application failed to install previously' do
      let(:ingress) { create(:clusters_applications_ingress, :errored, version: 'nginx') }

      it 'should be initialized with the locked version' do
        expect(subject.version).to eq('0.23.0')
      end
    end
  end

  describe '#files' do
    let(:application) { ingress }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include ingress valid keys in values' do
      expect(values).to include('image')
      expect(values).to include('repository')
      expect(values).to include('stats')
      expect(values).to include('podAnnotations')
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
