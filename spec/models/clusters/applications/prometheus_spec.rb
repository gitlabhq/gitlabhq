# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::Prometheus do
  include KubernetesHelpers
  include StubRequests

  include_examples 'cluster application core specs', :clusters_applications_prometheus
  include_examples 'cluster application status specs', :clusters_applications_prometheus
  include_examples 'cluster application version specs', :clusters_applications_prometheus
  include_examples 'cluster application helm specs', :clusters_applications_prometheus
  include_examples 'cluster application initial status specs'

  describe 'after_destroy' do
    let(:cluster) { create(:cluster, :with_installed_helm) }
    let(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    it 'disables the corresponding integration' do
      application.destroy!

      expect(cluster.integration_prometheus).not_to be_enabled
    end
  end

  describe 'transition to installed' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, :with_installed_helm) }
    let(:application) { create(:clusters_applications_prometheus, :installing, cluster: cluster) }

    it 'enables the corresponding integration' do
      application.make_installed

      expect(cluster.integration_prometheus).to be_enabled
    end
  end

  describe 'transition to externally_installed' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, :with_installed_helm) }
    let(:application) { create(:clusters_applications_prometheus, :installing, cluster: cluster) }

    it 'enables the corresponding integration' do
      application.make_externally_installed!

      expect(cluster.integration_prometheus).to be_enabled
    end
  end

  describe 'transition to updating' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    subject { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    it 'sets last_update_started_at to now' do
      freeze_time do
        expect { subject.make_updating }.to change { subject.reload.last_update_started_at }.to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#managed_prometheus?' do
    subject { prometheus.managed_prometheus? }

    let(:prometheus) { build(:clusters_applications_prometheus) }

    it { is_expected.to be_truthy }

    context 'externally installed' do
      let(:prometheus) { build(:clusters_applications_prometheus, :externally_installed) }

      it { is_expected.to be_falsey }
    end

    context 'uninstalled' do
      let(:prometheus) { build(:clusters_applications_prometheus, :uninstalled) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#can_uninstall?' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#prometheus_client' do
    include_examples '#prometheus_client shared' do
      let(:factory) { :clusters_applications_prometheus }
    end
  end

  describe '#install_command' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::InstallCommand) }

    it 'is initialized with 3 arguments' do
      expect(subject.name).to eq('prometheus')
      expect(subject.chart).to eq('prometheus/prometheus')
      expect(subject.version).to eq('10.4.1')
      expect(subject).to be_rbac
      expect(subject.files).to eq(prometheus.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        prometheus.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:prometheus) { create(:clusters_applications_prometheus, :errored, version: '2.0.0') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('10.4.1')
      end
    end

    it 'does not install knative metrics' do
      expect(subject.postinstall).to be_empty
    end

    context 'with knative installed' do
      let(:knative) { create(:clusters_applications_knative, :updated ) }
      let(:prometheus) { create(:clusters_applications_prometheus, cluster: knative.cluster) }

      subject { prometheus.install_command }

      it 'installs knative metrics' do
        expect(subject.postinstall).to include("kubectl apply -f #{Clusters::Applications::Knative::METRICS_CONFIG}")
      end
    end
  end

  describe '#uninstall_command' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::V3::DeleteCommand) }

    it 'has the application name' do
      expect(subject.name).to eq('prometheus')
    end

    it 'has files' do
      expect(subject.files).to eq(prometheus.files)
    end

    it 'is rbac' do
      expect(subject).to be_rbac
    end

    describe '#predelete' do
      let(:knative) { create(:clusters_applications_knative, :updated ) }
      let(:prometheus) { create(:clusters_applications_prometheus, cluster: knative.cluster) }

      subject { prometheus.uninstall_command.predelete }

      it 'deletes knative metrics' do
        metrics_config = Clusters::Applications::Knative::METRICS_CONFIG
        is_expected.to include("kubectl delete -f #{metrics_config} --ignore-not-found")
      end
    end

    context 'on a non rbac enabled cluster' do
      before do
        prometheus.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end
  end

  describe '#patch_command' do
    subject(:patch_command) { prometheus.patch_command(values) }

    let(:prometheus) { build(:clusters_applications_prometheus) }
    let(:values) { prometheus.values }

    it { is_expected.to be_an_instance_of(::Gitlab::Kubernetes::Helm::V3::PatchCommand) }

    it 'is initialized with 3 arguments' do
      expect(patch_command.name).to eq('prometheus')
      expect(patch_command.chart).to eq('prometheus/prometheus')
      expect(patch_command.version).to eq('10.4.1')
      expect(patch_command.files).to eq(prometheus.files)
    end
  end

  describe '#update_in_progress?' do
    context 'when app is updating' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = build(:clusters_applications_prometheus, :updating, cluster: cluster)

        expect(prometheus_app.update_in_progress?).to be true
      end
    end
  end

  describe '#update_errored?' do
    context 'when app errored' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = build(:clusters_applications_prometheus, :update_errored, cluster: cluster)

        expect(prometheus_app.update_errored?).to be true
      end
    end
  end

  describe '#files' do
    let(:application) { create(:clusters_applications_prometheus) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes prometheus valid values' do
      expect(values).to include('alertmanager')
      expect(values).to include('kubeStateMetrics')
      expect(values).to include('nodeExporter')
      expect(values).to include('pushgateway')
      expect(values).to include('serverFiles')
    end
  end

  describe '#files_with_replaced_values' do
    let(:application) { build(:clusters_applications_prometheus) }
    let(:files) { application.files }

    subject { application.files_with_replaced_values({ hello: :world }) }

    it 'does not modify #files' do
      expect(subject[:'values.yaml']).not_to eq(files[:'values.yaml'])

      expect(files[:'values.yaml']).to eq(application.values)
    end

    it 'returns values.yaml with replaced values' do
      expect(subject[:'values.yaml']).to eq({ hello: :world })
    end

    it 'uses values from #files, except for values.yaml' do
      allow(application).to receive(:files).and_return({
        'values.yaml': 'some value specific to files',
        'file_a.txt': 'file_a',
        'file_b.txt': 'file_b'
      })

      expect(subject.except(:'values.yaml')).to eq({
        'file_a.txt': 'file_a',
        'file_b.txt': 'file_b'
      })
    end
  end

  describe '#configured?' do
    let(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    subject { prometheus.configured? }

    context 'when a kubenetes client is present' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }

      it { is_expected.to be_truthy }

      context 'when it is not availalble' do
        let(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }

        it { is_expected.to be_falsey }
      end

      context 'when the kubernetes URL is blocked' do
        before do
          blocked_ip = '127.0.0.1' # localhost addresses are blocked by default

          stub_all_dns(cluster.platform.api_url, ip_address: blocked_ip)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when a kubenetes client is not present' do
      let(:cluster) { create(:cluster) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#updated_since?' do
    let(:cluster) { create(:cluster) }
    let(:prometheus_app) { build(:clusters_applications_prometheus, cluster: cluster) }
    let(:timestamp) { Time.current - 5.minutes }

    around do |example|
      freeze_time { example.run }
    end

    before do
      prometheus_app.last_update_started_at = Time.current
    end

    context 'when app does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(prometheus_app.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(prometheus_app.updated_since?(Time.current + 5.minutes)).to be false
      end
    end

    context 'when app has status failed' do
      it 'returns false when last update started after the timestamp' do
        prometheus_app.status = 6

        expect(prometheus_app.updated_since?(timestamp)).to be false
      end
    end
  end

  describe 'alert manager token' do
    subject { create(:clusters_applications_prometheus) }

    it 'is autogenerated on creation' do
      expect(subject.alert_manager_token).to match(/\A\h{32}\z/)
      expect(subject.encrypted_alert_manager_token).not_to be_nil
      expect(subject.encrypted_alert_manager_token_iv).not_to be_nil
    end
  end
end
