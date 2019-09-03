# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Ingress do
  let(:ingress) { create(:clusters_applications_ingress) }

  it_behaves_like 'having unique enum values'

  include_examples 'cluster application core specs', :clusters_applications_ingress
  include_examples 'cluster application status specs', :clusters_applications_ingress
  include_examples 'cluster application version specs', :clusters_applications_ingress
  include_examples 'cluster application helm specs', :clusters_applications_ingress
  include_examples 'cluster application initial status specs'

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
  end

  describe '#can_uninstall?' do
    subject { ingress.can_uninstall? }

    it 'returns true if application_jupyter_nil_or_installable? AND external_ip_or_hostname? are true' do
      ingress.external_ip = 'IP'

      is_expected.to be_truthy
    end

    it 'returns false if application_jupyter_nil_or_installable? is false' do
      create(:clusters_applications_jupyter, :installed, cluster: ingress.cluster)

      is_expected.to be_falsey
    end

    it 'returns false if external_ip_or_hostname? is false' do
      is_expected.to be_falsey
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

    context 'when there is already an external_hostname' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  describe '#install_command' do
    subject { ingress.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with ingress arguments' do
      expect(subject.name).to eq('ingress')
      expect(subject.chart).to eq('stable/nginx-ingress')
      expect(subject.version).to eq('1.1.2')
      expect(subject).to be_rbac
      expect(subject.files).to eq(ingress.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        ingress.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:ingress) { create(:clusters_applications_ingress, :errored, version: 'nginx') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('1.1.2')
      end
    end
  end

  describe '#files' do
    let(:application) { ingress }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes ingress valid keys in values' do
      expect(values).to include('image')
      expect(values).to include('repository')
      expect(values).to include('stats')
      expect(values).to include('podAnnotations')
    end
  end
end
