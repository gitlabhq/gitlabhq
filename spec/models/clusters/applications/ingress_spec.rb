# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::Ingress do
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

    context 'with jupyter installed' do
      before do
        create(:clusters_applications_jupyter, :installed, cluster: ingress.cluster)
      end

      it 'returns false if external_ip_or_hostname? is true' do
        ingress.external_ip = 'IP'

        is_expected.to be_falsey
      end

      it 'returns false if external_ip_or_hostname? is false' do
        is_expected.to be_falsey
      end
    end

    context 'with jupyter installable' do
      before do
        create(:clusters_applications_jupyter, :installable, cluster: ingress.cluster)
      end

      it 'returns true if external_ip_or_hostname? is true' do
        ingress.external_ip = 'IP'

        is_expected.to be_truthy
      end

      it 'returns false if external_ip_or_hostname? is false' do
        is_expected.to be_falsey
      end
    end

    context 'with jupyter nil' do
      it 'returns false if external_ip_or_hostname? is false' do
        is_expected.to be_falsey
      end

      context 'if external_ip_or_hostname? is true' do
        context 'with IP' do
          before do
            ingress.external_ip = 'IP'
          end

          it { is_expected.to be_truthy }
        end

        context 'with hostname' do
          before do
            ingress.external_hostname = 'example.com'
          end

          it { is_expected.to be_truthy }
        end
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

    context 'when there is already an external_hostname' do
      let(:application) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  describe '#install_command' do
    subject { ingress.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::InstallCommand) }

    it 'is initialized with ingress arguments' do
      expect(subject.name).to eq('ingress')
      expect(subject.chart).to eq('ingress/nginx-ingress')
      expect(subject.version).to eq('1.40.2')
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
        expect(subject.version).to eq('1.40.2')
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
      expect(values).to include('clusterIP')
    end
  end
end
