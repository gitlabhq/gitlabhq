# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Cluster, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers
  include KubernetesHelpers

  it_behaves_like 'having unique enum values'

  subject { build(:cluster) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:management_project).class_name('::Project') }
  it { is_expected.to have_many(:cluster_projects) }
  it { is_expected.to have_many(:projects) }
  it { is_expected.to have_many(:cluster_groups) }
  it { is_expected.to have_many(:groups) }
  it { is_expected.to have_one(:provider_gcp) }
  it { is_expected.to have_one(:provider_aws) }
  it { is_expected.to have_one(:platform_kubernetes) }
  it { is_expected.to have_one(:application_helm) }
  it { is_expected.to have_one(:application_ingress) }
  it { is_expected.to have_one(:application_prometheus) }
  it { is_expected.to have_one(:application_runner) }
  it { is_expected.to have_many(:kubernetes_namespaces) }
  it { is_expected.to have_one(:cluster_project) }

  it { is_expected.to delegate_method(:status).to(:provider) }
  it { is_expected.to delegate_method(:status_reason).to(:provider) }
  it { is_expected.to delegate_method(:on_creation?).to(:provider) }
  it { is_expected.to delegate_method(:knative_pre_installed?).to(:provider) }
  it { is_expected.to delegate_method(:active?).to(:platform_kubernetes).with_prefix }
  it { is_expected.to delegate_method(:rbac?).to(:platform_kubernetes).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_helm).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_ingress).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_prometheus).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_knative).with_prefix }
  it { is_expected.to delegate_method(:external_ip).to(:application_ingress).with_prefix }
  it { is_expected.to delegate_method(:external_hostname).to(:application_ingress).with_prefix }

  it { is_expected.to respond_to :project }

  describe 'applications have inverse_of: :cluster option' do
    let(:cluster) { create(:cluster) }
    let!(:helm) { create(:clusters_applications_helm, cluster: cluster) }

    it 'does not do a third query when referencing cluster again' do
      expect { cluster.application_helm.cluster }.not_to exceed_query_limit(2)
    end
  end

  describe '.enabled' do
    subject { described_class.enabled }

    let!(:cluster) { create(:cluster, enabled: true) }

    before do
      create(:cluster, :disabled)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.disabled' do
    subject { described_class.disabled }

    let!(:cluster) { create(:cluster, :disabled) }

    before do
      create(:cluster, enabled: true)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.user_provided' do
    subject { described_class.user_provided }

    let!(:cluster) { create(:cluster_platform_kubernetes).cluster }

    before do
      create(:cluster_provider_gcp, :created)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.gcp_provided' do
    subject { described_class.gcp_provided }

    let!(:cluster) { create(:cluster_provider_gcp, :created).cluster }

    before do
      create(:cluster, :provided_by_user)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.gcp_installed' do
    subject { described_class.gcp_installed }

    let!(:cluster) { create(:cluster_provider_gcp, :created).cluster }

    before do
      create(:cluster, :providing_by_gcp)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.aws_provided' do
    subject { described_class.aws_provided }

    let!(:cluster) { create(:cluster_provider_aws, :created).cluster }

    before do
      create(:cluster, :provided_by_user)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.aws_installed' do
    subject { described_class.aws_installed }

    let!(:cluster) { create(:cluster_provider_aws, :created).cluster }

    before do
      errored_provider = create(:cluster_provider_aws)
      errored_provider.make_errored!("Error message")
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.managed' do
    subject do
      described_class.managed
    end

    context 'cluster is not managed' do
      let!(:cluster) { create(:cluster, :not_managed) }

      it { is_expected.not_to include(cluster) }
    end

    context 'cluster is managed' do
      let!(:cluster) { create(:cluster) }

      it { is_expected.to include(cluster) }
    end
  end

  describe '.for_project_namespace' do
    subject { described_class.for_project_namespace(namespace_id) }

    let!(:cluster) { create(:cluster, :project) }
    let!(:another_cluster) { create(:cluster, :project) }
    let(:namespace_id) { cluster.first_project.namespace_id }

    it { is_expected.to contain_exactly(cluster) }
  end

  describe 'validations' do
    subject { cluster.valid? }

    context 'when validates name' do
      context 'when provided by user' do
        let!(:cluster) { build(:cluster, :provided_by_user, name: name) }

        context 'when name is empty' do
          let(:name) { '' }

          it { is_expected.to be_falsey }
        end

        context 'when name is nil' do
          let(:name) { nil }

          it { is_expected.to be_falsey }
        end

        context 'when name is present' do
          let(:name) { 'cluster-name-1' }

          it { is_expected.to be_truthy }
        end
      end

      context 'when provided by gcp' do
        let!(:cluster) { build(:cluster, :provided_by_gcp, name: name) }

        context 'when name is shorter than 1' do
          let(:name) { '' }

          it { is_expected.to be_falsey }
        end

        context 'when name is longer than 63' do
          let(:name) { 'a' * 64 }

          it { is_expected.to be_falsey }
        end

        context 'when name includes invalid character' do
          let(:name) { '!!!!!!' }

          it { is_expected.to be_falsey }
        end

        context 'when name is present' do
          let(:name) { 'cluster-name-1' }

          it { is_expected.to be_truthy }
        end

        context 'when record is persisted' do
          let(:name) { 'cluster-name-1' }

          before do
            cluster.save!
          end

          context 'when name is changed' do
            before do
              cluster.name = 'new-cluster-name'
            end

            it { is_expected.to be_falsey }
          end

          context 'when name is same' do
            before do
              cluster.name = name
            end

            it { is_expected.to be_truthy }
          end
        end
      end
    end

    context 'when validates restrict_modification' do
      context 'when creation is on going' do
        let!(:cluster) { create(:cluster, :providing_by_gcp) }

        it { expect(cluster.update(enabled: false)).to be_falsey }
      end

      context 'when creation is done' do
        let!(:cluster) { create(:cluster, :provided_by_gcp) }

        it { expect(cluster.update(enabled: false)).to be_truthy }
      end
    end

    describe 'cluster_type validations' do
      let(:instance_cluster) { create(:cluster, :instance) }
      let(:group_cluster) { create(:cluster, :group) }
      let(:project_cluster) { create(:cluster, :project) }

      it 'validates presence' do
        cluster = build(:cluster, :project, cluster_type: nil)

        expect(cluster).not_to be_valid
        expect(cluster.errors.full_messages).to include("Cluster type can't be blank")
      end

      context 'project_type cluster' do
        it 'does not allow setting group' do
          project_cluster.groups << build(:group)

          expect(project_cluster).not_to be_valid
          expect(project_cluster.errors.full_messages).to include('Cluster cannot have groups assigned')
        end
      end

      context 'group_type cluster' do
        it 'does not allow setting project' do
          group_cluster.projects << build(:project)

          expect(group_cluster).not_to be_valid
          expect(group_cluster.errors.full_messages).to include('Cluster cannot have projects assigned')
        end
      end

      context 'instance_type cluster' do
        it 'does not allow setting group' do
          instance_cluster.groups << build(:group)

          expect(instance_cluster).not_to be_valid
          expect(instance_cluster.errors.full_messages).to include('Cluster cannot have groups assigned')
        end

        it 'does not allow setting project' do
          instance_cluster.projects << build(:project)

          expect(instance_cluster).not_to be_valid
          expect(instance_cluster.errors.full_messages).to include('Cluster cannot have projects assigned')
        end
      end
    end

    describe 'domain validation' do
      let(:cluster) { build(:cluster) }

      subject { cluster }

      context 'when cluster has domain' do
        let(:cluster) { build(:cluster, :with_domain) }

        it { is_expected.to be_valid }
      end

      context 'when cluster is not a valid hostname' do
        let(:cluster) { build(:cluster, domain: 'http://not.a.valid.hostname') }

        it 'adds an error on domain' do
          expect(subject).not_to be_valid
          expect(subject.errors[:domain].first).to eq('contains invalid characters (valid characters: [a-z0-9\\-])')
        end
      end

      context 'when cluster does not have a domain' do
        it { is_expected.to be_valid }
      end
    end

    describe 'unique scope for management_project' do
      let(:project) { create(:project) }
      let!(:cluster_with_management_project) { create(:cluster, management_project: project) }

      context 'duplicate scopes for the same management project' do
        let(:cluster) { build(:cluster, management_project: project) }

        it 'adds an error on environment_scope' do
          expect(cluster).not_to be_valid
          expect(cluster.errors[:environment_scope].first).to eq('cannot add duplicated environment scope')
        end
      end
    end
  end

  describe '.ancestor_clusters_for_clusterable' do
    let(:group_cluster) { create(:cluster, :provided_by_gcp, :group) }
    let(:group) { group_cluster.group }
    let(:hierarchy_order) { :desc }
    let(:clusterable) { project }

    subject do
      described_class.ancestor_clusters_for_clusterable(clusterable, hierarchy_order: hierarchy_order)
    end

    context 'when project does not belong to this group' do
      let(:project) { create(:project, group: create(:group)) }

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when group has a configured kubernetes cluster' do
      let(:project) { create(:project, group: group) }

      it 'returns the group cluster' do
        is_expected.to eq([group_cluster])
      end
    end

    context 'when group and instance have configured kubernetes clusters' do
      let(:project) { create(:project, group: group) }
      let!(:instance_cluster) { create(:cluster, :provided_by_gcp, :instance) }

      it 'returns clusters in order, descending the hierachy' do
        is_expected.to eq([group_cluster, instance_cluster])
      end
    end

    context 'when sub-group has configured kubernetes cluster' do
      let(:sub_group_cluster) { create(:cluster, :provided_by_gcp, :group) }
      let(:sub_group) { sub_group_cluster.group }
      let(:project) { create(:project, group: sub_group) }

      before do
        sub_group.update!(parent: group)
      end

      it 'returns clusters in order, descending the hierachy' do
        is_expected.to eq([group_cluster, sub_group_cluster])
      end

      it 'avoids N+1 queries' do
        another_project = create(:project)
        control_count = ActiveRecord::QueryRecorder.new do
          described_class.ancestor_clusters_for_clusterable(another_project, hierarchy_order: hierarchy_order)
        end.count

        cluster2 = create(:cluster, :provided_by_gcp, :group)
        child2 = cluster2.group
        child2.update!(parent: sub_group)
        project = create(:project, group: child2)

        expect do
          described_class.ancestor_clusters_for_clusterable(project, hierarchy_order: hierarchy_order)
        end.not_to exceed_query_limit(control_count)
      end

      context 'for a group' do
        let(:clusterable) { sub_group }

        it 'returns clusters in order for a group' do
          is_expected.to eq([group_cluster])
        end
      end
    end

    context 'scope chaining' do
      let(:project) { create(:project, group: group) }

      subject { described_class.none.ancestor_clusters_for_clusterable(project) }

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end
  end

  describe '#provider' do
    subject { cluster.provider }

    context 'when provider is gcp' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }

      it 'returns a provider' do
        is_expected.to eq(cluster.provider_gcp)
      end
    end

    context 'when provider is aws' do
      let(:cluster) { create(:cluster, :provided_by_aws) }

      it 'returns a provider' do
        is_expected.to eq(cluster.provider_aws)
      end
    end

    context 'when provider is user' do
      let(:cluster) { create(:cluster, :provided_by_user) }

      it { is_expected.to be_nil }
    end
  end

  describe '#platform' do
    subject { cluster.platform }

    context 'when platform is kubernetes' do
      let(:cluster) { create(:cluster, :provided_by_user) }

      it 'returns a platform' do
        is_expected.to eq(cluster.platform_kubernetes)
        expect(subject.class.name.deconstantize).to eq(Clusters::Platforms.to_s)
      end
    end
  end

  describe '#first_project' do
    subject { cluster.first_project }

    context 'when cluster belongs to a project' do
      let(:cluster) { create(:cluster, :project) }
      let(:project) { Clusters::Project.find_by_cluster_id(cluster.id).project }

      it { is_expected.to eq(project) }
    end

    context 'when cluster does not belong to projects' do
      let(:cluster) { create(:cluster) }

      it { is_expected.to be_nil }
    end
  end

  describe '#group' do
    subject { cluster.group }

    context 'when cluster belongs to a group' do
      let(:cluster) { create(:cluster, :group) }
      let(:group) { cluster.groups.first }

      it { is_expected.to eq(group) }
    end

    context 'when cluster does not belong to any group' do
      let(:cluster) { create(:cluster) }

      it { is_expected.to be_nil }
    end
  end

  describe '.with_persisted_applications' do
    let(:cluster) { create(:cluster) }
    let!(:helm) { create(:clusters_applications_helm, :installed, cluster: cluster) }

    it 'preloads persisted applications' do
      query_rec = ActiveRecord::QueryRecorder.new do
        described_class.with_persisted_applications.find_by_id(cluster.id).application_helm
      end

      expect(query_rec.count).to eq(1)
    end
  end

  describe '#persisted_applications' do
    let(:cluster) { create(:cluster) }

    subject { cluster.persisted_applications }

    context 'when all applications are created' do
      let!(:helm) { create(:clusters_applications_helm, cluster: cluster) }
      let!(:ingress) { create(:clusters_applications_ingress, cluster: cluster) }
      let!(:cert_manager) { create(:clusters_applications_cert_manager, cluster: cluster) }
      let!(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }
      let!(:runner) { create(:clusters_applications_runner, cluster: cluster) }
      let!(:jupyter) { create(:clusters_applications_jupyter, cluster: cluster) }
      let!(:knative) { create(:clusters_applications_knative, cluster: cluster) }

      it 'returns a list of created applications' do
        is_expected.to contain_exactly(helm, ingress, cert_manager, prometheus, runner, jupyter, knative)
      end
    end

    context 'when not all were created' do
      let!(:helm) { create(:clusters_applications_helm, cluster: cluster) }
      let!(:ingress) { create(:clusters_applications_ingress, cluster: cluster) }

      it 'returns a list of created applications' do
        is_expected.to contain_exactly(helm, ingress)
      end
    end
  end

  describe '#applications' do
    set(:cluster) { create(:cluster) }

    subject { cluster.applications }

    context 'when none of applications are created' do
      it 'returns a list of a new objects' do
        is_expected.not_to be_empty
      end
    end

    context 'when applications are created' do
      let!(:helm) { create(:clusters_applications_helm, cluster: cluster) }
      let!(:ingress) { create(:clusters_applications_ingress, cluster: cluster) }
      let!(:cert_manager) { create(:clusters_applications_cert_manager, cluster: cluster) }
      let!(:crossplane) { create(:clusters_applications_crossplane, cluster: cluster) }
      let!(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }
      let!(:runner) { create(:clusters_applications_runner, cluster: cluster) }
      let!(:jupyter) { create(:clusters_applications_jupyter, cluster: cluster) }
      let!(:knative) { create(:clusters_applications_knative, cluster: cluster) }
      let!(:elastic_stack) { create(:clusters_applications_elastic_stack, cluster: cluster) }

      it 'returns a list of created applications' do
        is_expected.to contain_exactly(helm, ingress, cert_manager, crossplane, prometheus, runner, jupyter, knative, elastic_stack)
      end
    end
  end

  describe '#allow_user_defined_namespace?' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { cluster.allow_user_defined_namespace? }

    context 'project type cluster' do
      context 'gitlab managed' do
        it { is_expected.to be_truthy }
      end

      context 'not managed' do
        let(:cluster) { create(:cluster, :provided_by_gcp, managed: false) }

        it { is_expected.to be_truthy }
      end
    end

    context 'group type cluster' do
      context 'gitlab managed' do
        let(:cluster) { create(:cluster, :provided_by_gcp, :group) }

        it { is_expected.to be_falsey }
      end

      context 'not managed' do
        let(:cluster) { create(:cluster, :provided_by_gcp, :group, managed: false) }

        it { is_expected.to be_truthy }
      end
    end

    context 'instance type cluster' do
      context 'gitlab managed' do
        let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

        it { is_expected.to be_falsey }
      end

      context 'not managed' do
        let(:cluster) { create(:cluster, :provided_by_gcp, :instance, managed: false) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#kube_ingress_domain' do
    let(:cluster) { create(:cluster, :provided_by_gcp) }

    subject { cluster.kube_ingress_domain }

    context 'with domain set in cluster' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :with_domain) }

      it { is_expected.to eq(cluster.domain) }
    end

    context 'with no domain on cluster' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:project) { cluster.project }

      context 'with domain set at instance level' do
        before do
          stub_application_setting(auto_devops_domain: 'global_domain.com')
        end

        it { is_expected.to eq('global_domain.com') }
      end
    end
  end

  describe '#kubernetes_namespace_for' do
    let(:cluster) { create(:cluster, :group) }
    let(:environment) { create(:environment) }

    subject { cluster.kubernetes_namespace_for(environment) }

    before do
      expect(Clusters::KubernetesNamespaceFinder).to receive(:new)
        .with(cluster, project: environment.project, environment_name: environment.name)
        .and_return(double(execute: persisted_namespace))
    end

    context 'a persisted namespace exists' do
      let(:persisted_namespace) { create(:cluster_kubernetes_namespace) }

      it { is_expected.to eq persisted_namespace.namespace }
    end

    context 'no persisted namespace exists' do
      let(:persisted_namespace) { nil }
      let(:namespace_generator) { double }
      let(:default_namespace) { 'a-default-namespace' }

      before do
        expect(Gitlab::Kubernetes::DefaultNamespace).to receive(:new)
          .with(cluster, project: environment.project)
          .and_return(namespace_generator)
        expect(namespace_generator).to receive(:from_environment_slug)
          .with(environment.slug)
          .and_return(default_namespace)
      end

      it { is_expected.to eq default_namespace }
    end
  end

  describe '#predefined_variables' do
    subject { cluster.predefined_variables }

    context 'with an instance domain' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }

      before do
        stub_application_setting(auto_devops_domain: 'global_domain.com')
      end

      it 'includes KUBE_INGRESS_BASE_DOMAIN' do
        expect(subject.to_hash).to include(KUBE_INGRESS_BASE_DOMAIN: 'global_domain.com')
      end
    end

    context 'with a cluster domain' do
      let(:cluster) { create(:cluster, :provided_by_gcp, domain: 'example.com') }

      it 'includes KUBE_INGRESS_BASE_DOMAIN' do
        expect(subject.to_hash).to include(KUBE_INGRESS_BASE_DOMAIN: 'example.com')
      end
    end

    context 'with no domain' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :project) }

      it 'returns an empty array' do
        expect(subject.to_hash).to be_empty
      end
    end
  end

  describe '#provided_by_user?' do
    subject { cluster.provided_by_user? }

    context 'with a GCP provider' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }

      it { is_expected.to be_falsy }
    end

    context 'with an user provider' do
      let(:cluster) { create(:cluster, :provided_by_user) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#status_name' do
    subject { cluster.status_name }

    context 'the cluster has a provider' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }
      let(:provider_status) { :errored }

      before do
        cluster.provider.make_errored!
      end

      it { is_expected.to eq provider_status }

      context 'when cluster cleanup is ongoing' do
        using RSpec::Parameterized::TableSyntax

        where(:status_name, :cleanup_status) do
          provider_status  | :cleanup_not_started
          :cleanup_ongoing | :cleanup_uninstalling_applications
          :cleanup_ongoing | :cleanup_removing_project_namespaces
          :cleanup_ongoing | :cleanup_removing_service_account
          :cleanup_errored | :cleanup_errored
        end

        with_them do
          it 'returns cleanup_ongoing when uninstalling applications' do
            cluster.cleanup_status = described_class
              .state_machines[:cleanup_status]
              .states[cleanup_status]
              .value

            is_expected.to eq status_name
          end
        end
      end
    end

    context 'there is a cached connection status' do
      let(:cluster) { create(:cluster, :provided_by_user) }

      before do
        allow(cluster).to receive(:connection_status).and_return(:connected)
      end

      it { is_expected.to eq :connected }
    end

    context 'there is no connection status in the cache' do
      let(:cluster) { create(:cluster, :provided_by_user) }

      before do
        allow(cluster).to receive(:connection_status).and_return(nil)
      end

      it { is_expected.to eq :created }
    end
  end

  describe 'cleanup_status state_machine' do
    shared_examples 'cleanup_status transition' do
      let(:cluster) { create(:cluster, from_state) }

      it 'transitions cleanup_status correctly' do
        expect { subject }.to change { cluster.cleanup_status_name }
          .from(from_state).to(to_state)
      end

      it 'schedules a Clusters::Cleanup::*Worker' do
        expect(expected_worker_class).to receive(:perform_async).with(cluster.id)
        subject
      end
    end

    describe '#start_cleanup!' do
      let(:expected_worker_class) { Clusters::Cleanup::AppWorker }
      let(:to_state) { :cleanup_uninstalling_applications }

      subject { cluster.start_cleanup! }

      context 'when cleanup_status is cleanup_not_started' do
        let(:from_state) { :cleanup_not_started }

        it_behaves_like 'cleanup_status transition'
      end

      context 'when cleanup_status is errored' do
        let(:from_state) { :cleanup_errored }

        it_behaves_like 'cleanup_status transition'
      end
    end

    describe '#make_cleanup_errored!' do
      NON_ERRORED_STATES = Clusters::Cluster.state_machines[:cleanup_status].states.keys - [:cleanup_errored]

      NON_ERRORED_STATES.each do |state|
        it "transitions cleanup_status from #{state} to cleanup_errored" do
          cluster = create(:cluster, state)

          expect { cluster.make_cleanup_errored! }.to change { cluster.cleanup_status_name }
            .from(state).to(:cleanup_errored)
        end

        it "sets error message" do
          cluster = create(:cluster, state)

          expect { cluster.make_cleanup_errored!("Error Message") }.to change { cluster.cleanup_status_reason }
            .from(nil).to("Error Message")
        end
      end
    end

    describe '#continue_cleanup!' do
      context 'when cleanup_status is cleanup_uninstalling_applications' do
        let(:expected_worker_class) { Clusters::Cleanup::ProjectNamespaceWorker }
        let(:from_state) { :cleanup_uninstalling_applications }
        let(:to_state) { :cleanup_removing_project_namespaces }

        subject { cluster.continue_cleanup! }

        it_behaves_like 'cleanup_status transition'
      end

      context 'when cleanup_status is cleanup_removing_project_namespaces' do
        let(:expected_worker_class) { Clusters::Cleanup::ServiceAccountWorker }
        let(:from_state) { :cleanup_removing_project_namespaces }
        let(:to_state) { :cleanup_removing_service_account }

        subject { cluster.continue_cleanup! }

        it_behaves_like 'cleanup_status transition'
      end
    end
  end

  describe '#connection_status' do
    let(:cluster) { create(:cluster) }
    let(:status) { :connected }

    subject { cluster.connection_status }

    it { is_expected.to be_nil }

    context 'with a cached status' do
      before do
        stub_reactive_cache(cluster, connection_status: status)
      end

      it { is_expected.to eq(status) }
    end
  end

  describe '#calculate_reactive_cache' do
    subject { cluster.calculate_reactive_cache }

    context 'cluster is disabled' do
      let(:cluster) { create(:cluster, :disabled) }

      it 'does not populate the cache' do
        expect(cluster).not_to receive(:retrieve_connection_status)

        is_expected.to be_nil
      end
    end

    context 'cluster is enabled' do
      let(:cluster) { create(:cluster, :provided_by_user, :group) }

      context 'connection to the cluster is successful' do
        before do
          stub_kubeclient_discover(cluster.platform.api_url)
        end

        it { is_expected.to eq(connection_status: :connected) }
      end

      context 'cluster cannot be reached' do
        before do
          allow(cluster.kubeclient.core_client).to receive(:discover)
            .and_raise(SocketError)
        end

        it { is_expected.to eq(connection_status: :unreachable) }
      end

      context 'cluster cannot be authenticated to' do
        before do
          allow(cluster.kubeclient.core_client).to receive(:discover)
            .and_raise(OpenSSL::X509::CertificateError.new("Certificate error"))
        end

        it { is_expected.to eq(connection_status: :authentication_failure) }
      end

      describe 'Kubeclient::HttpError' do
        let(:error_code) { 403 }
        let(:error_message) { "Forbidden" }

        before do
          allow(cluster.kubeclient.core_client).to receive(:discover)
            .and_raise(Kubeclient::HttpError.new(error_code, error_message, nil))
        end

        it { is_expected.to eq(connection_status: :authentication_failure) }

        context 'generic timeout' do
          let(:error_message) { 'Timed out connecting to server'}

          it { is_expected.to eq(connection_status: :unreachable) }
        end

        context 'gateway timeout' do
          let(:error_message) { '504 Gateway Timeout for GET https://kubernetes.example.com/api/v1'}

          it { is_expected.to eq(connection_status: :unreachable) }
        end
      end

      context 'an uncategorised error is raised' do
        before do
          allow(cluster.kubeclient.core_client).to receive(:discover)
            .and_raise(StandardError)
        end

        it { is_expected.to eq(connection_status: :unknown_failure) }

        it 'notifies Sentry' do
          expect(Gitlab::Sentry).to receive(:track_acceptable_exception)
            .with(instance_of(StandardError), hash_including(extra: { cluster_id: cluster.id }))

          subject
        end
      end
    end
  end

  describe '#delete_cached_resources!' do
    let!(:cluster) { create(:cluster, :project) }
    let!(:staging_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, namespace: 'staging') }
    let!(:production_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, namespace: 'production') }

    subject { cluster.delete_cached_resources! }

    it 'deletes associated namespace records' do
      expect(cluster.kubernetes_namespaces).to match_array([staging_namespace, production_namespace])

      subject

      expect(cluster.kubernetes_namespaces).to be_empty
    end
  end
end
