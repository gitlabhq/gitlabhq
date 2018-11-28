require 'rails_helper'

describe Clusters::Applications::Knative do
  let(:knative) { create(:clusters_applications_knative) }

  include_examples 'cluster application core specs', :clusters_applications_knative
  include_examples 'cluster application status specs', :clusters_applications_knative
  include_examples 'cluster application helm specs', :clusters_applications_knative

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
  end

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

  describe 'make_installed with external_ip' do
    before do
      application.make_installed!
    end

    let(:application) { create(:clusters_applications_knative, :installing) }

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_in)
        .with(Clusters::Applications::Knative::FETCH_IP_ADDRESS_DELAY, 'knative', application.id)
    end
  end

  describe '#schedule_status_update with external_ip' do
    let(:application) { create(:clusters_applications_knative, :installed) }

    before do
      application.schedule_status_update
    end

    it 'schedules a ClusterWaitForIngressIpAddressWorker' do
      expect(ClusterWaitForIngressIpAddressWorker).to have_received(:perform_async)
        .with('knative', application.id)
    end

    context 'when the application is not installed' do
      let(:application) { create(:clusters_applications_knative, :installing) }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_async)
      end
    end

    context 'when there is already an external_ip' do
      let(:application) { create(:clusters_applications_knative, :installed, external_ip: '111.222.222.111') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  describe '#install_command' do
    subject { knative.install_command }

    it 'should be an instance of Helm::InstallCommand' do
      expect(subject).to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand)
    end

    it 'should be initialized with knative arguments' do
      expect(subject.name).to eq('knative')
      expect(subject.chart).to eq('knative/knative')
      expect(subject.version).to eq('0.1.3')
      expect(subject.files).to eq(knative.files)
    end
  end

  describe '#files' do
    let(:application) { knative }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'should include knative specific keys in the values.yaml file' do
      expect(values).to include('domain')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:hostname) }
  end
end
