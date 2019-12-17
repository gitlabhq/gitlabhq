# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Knative do
  let(:knative) { create(:clusters_applications_knative) }

  include_examples 'cluster application core specs', :clusters_applications_knative
  include_examples 'cluster application status specs', :clusters_applications_knative
  include_examples 'cluster application helm specs', :clusters_applications_knative
  include_examples 'cluster application version specs', :clusters_applications_knative
  include_examples 'cluster application initial status specs'

  before do
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_in)
    allow(ClusterWaitForIngressIpAddressWorker).to receive(:perform_async)
  end

  describe 'associations' do
    it { is_expected.to have_one(:serverless_domain_cluster).class_name('Serverless::DomainCluster').with_foreign_key('clusters_applications_knative_id').inverse_of(:knative) }
  end

  describe 'when cloud run is enabled' do
    let(:cluster) { create(:cluster, :provided_by_gcp, :cloud_run_enabled) }
    let(:knative_cloud_run) { create(:clusters_applications_knative, cluster: cluster) }

    it { expect(knative_cloud_run).to be_not_installable }
  end

  describe 'when rbac is not enabled' do
    let(:cluster) { create(:cluster, :provided_by_gcp, :rbac_disabled) }
    let(:knative_no_rbac) { create(:clusters_applications_knative, cluster: cluster) }

    it { expect(knative_no_rbac).to be_not_installable }
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

  describe '#can_uninstall?' do
    subject { knative.can_uninstall? }

    it { is_expected.to be_truthy }
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

    context 'when there is already an external_hostname' do
      let(:application) { create(:clusters_applications_knative, :installed, external_hostname: 'localhost.localdomain') }

      it 'does not schedule a ClusterWaitForIngressIpAddressWorker' do
        expect(ClusterWaitForIngressIpAddressWorker).not_to have_received(:perform_in)
      end
    end
  end

  shared_examples 'a command' do
    it 'is an instance of Helm::InstallCommand' do
      expect(subject).to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand)
    end

    it 'is initialized with knative arguments' do
      expect(subject.name).to eq('knative')
      expect(subject.chart).to eq('knative/knative')
      expect(subject.files).to eq(knative.files)
    end

    it 'does not install metrics for prometheus' do
      expect(subject.postinstall).to be_empty
    end

    context 'with prometheus installed' do
      let(:prometheus) { create(:clusters_applications_prometheus, :installed) }
      let(:knative) { create(:clusters_applications_knative, cluster: prometheus.cluster) }

      subject { knative.install_command }

      it 'installs metrics' do
        expect(subject.postinstall).not_to be_empty
        expect(subject.postinstall.length).to be(1)
        expect(subject.postinstall[0]).to eql("kubectl apply -f #{Clusters::Applications::Knative::METRICS_CONFIG}")
      end
    end
  end

  describe '#install_command' do
    subject { knative.install_command }

    it 'is initialized with latest version' do
      expect(subject.version).to eq('0.9.0')
    end

    it_behaves_like 'a command'
  end

  describe '#update_command' do
    let!(:current_installed_version) { knative.version = '0.1.0' }
    subject { knative.update_command }

    it 'is initialized with current version' do
      expect(subject.version).to eq(current_installed_version)
    end

    it_behaves_like 'a command'
  end

  describe '#uninstall_command' do
    subject { knative.uninstall_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::DeleteCommand) }

    it "removes knative deployed services before uninstallation" do
      2.times do |i|
        cluster_project = create(:cluster_project, cluster: knative.cluster)

        create(:cluster_kubernetes_namespace,
          cluster: cluster_project.cluster,
          cluster_project: cluster_project,
          project: cluster_project.project,
          namespace: "namespace_#{i}")
      end

      remove_namespaced_services_script = [
        "kubectl delete ksvc --all -n #{knative.cluster.kubernetes_namespaces.first.namespace}",
        "kubectl delete ksvc --all -n #{knative.cluster.kubernetes_namespaces.second.namespace}"
      ]

      expect(subject.predelete).to match_array(remove_namespaced_services_script)
    end

    it "initializes command with all necessary postdelete script" do
      api_groups = YAML.safe_load(File.read(Rails.root.join(Clusters::Applications::Knative::API_GROUPS_PATH)))

      remove_knative_istio_leftovers_script = [
        "kubectl delete --ignore-not-found ns knative-serving",
        "kubectl delete --ignore-not-found ns knative-build"
      ]

      full_delete_commands_size = api_groups.size + remove_knative_istio_leftovers_script.size

      expect(subject.postdelete).to include(*remove_knative_istio_leftovers_script)
      expect(subject.postdelete.size).to eq(full_delete_commands_size)
      expect(subject.postdelete[2]).to eq("kubectl api-resources -o name --api-group #{api_groups[0]} | xargs kubectl delete --ignore-not-found crd")
      expect(subject.postdelete[3]).to eq("kubectl api-resources -o name --api-group #{api_groups[1]} | xargs kubectl delete --ignore-not-found crd")
    end
  end

  describe '#files' do
    let(:application) { knative }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    it 'includes knative specific keys in the values.yaml file' do
      expect(values).to include('domain')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:hostname) }
  end
end
