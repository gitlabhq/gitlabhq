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

    it 'returns true if external ip is set and no application exists' do
      ingress.external_ip = 'IP'

      is_expected.to be_truthy
    end

    it 'returns false if application_jupyter_nil_or_installable? is false' do
      create(:clusters_applications_jupyter, :installed, cluster: ingress.cluster)

      is_expected.to be_falsey
    end

    it 'returns false if application_elastic_stack_nil_or_installable? is false' do
      create(:clusters_applications_elastic_stack, :installed, cluster: ingress.cluster)

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
      expect(subject.version).to eq('1.22.1')
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
        expect(subject.version).to eq('1.22.1')
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

  describe '#values' do
    let(:project) { build(:project) }
    let(:cluster) { build(:cluster, projects: [project]) }

    context 'when modsecurity_enabled is enabled' do
      before do
        allow(subject).to receive(:cluster).and_return(cluster)

        allow(subject).to receive(:modsecurity_enabled).and_return(true)
      end

      it 'includes modsecurity module enablement' do
        expect(subject.values).to include("enable-modsecurity: 'true'")
      end

      it 'includes modsecurity core ruleset enablement' do
        expect(subject.values).to include("enable-owasp-modsecurity-crs: 'true'")
      end

      it 'includes modsecurity.conf content' do
        expect(subject.values).to include('modsecurity.conf')
        # Includes file content from Ingress#modsecurity_config_content
        expect(subject.values).to include('SecAuditLog')

        expect(subject.values).to include('extraVolumes')
        expect(subject.values).to include('extraVolumeMounts')
      end

      it 'includes modsecurity sidecar container' do
        expect(subject.values).to include('modsecurity-log-volume')

        expect(subject.values).to include('extraContainers')
      end
    end

    context 'when modsecurity_enabled is disabled' do
      before do
        allow(subject).to receive(:cluster).and_return(cluster)
      end

      it 'excludes modsecurity module enablement' do
        expect(subject.values).not_to include('enable-modsecurity')
      end

      it 'excludes modsecurity core ruleset enablement' do
        expect(subject.values).not_to include('enable-owasp-modsecurity-crs')
      end

      it 'excludes modsecurity.conf content' do
        expect(subject.values).not_to include('modsecurity.conf')
        # Excludes file content from Ingress#modsecurity_config_content
        expect(subject.values).not_to include('SecAuditLog')

        expect(subject.values).not_to include('extraVolumes')
        expect(subject.values).not_to include('extraVolumeMounts')
      end

      it 'excludes modsecurity sidecar container' do
        expect(subject.values).not_to include('modsecurity-log-volume')

        expect(subject.values).not_to include('extraContainers')
      end
    end
  end
end
