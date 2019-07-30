# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Cluster, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers
  include KubernetesHelpers

  it_behaves_like 'having unique enum values'

  subject { build(:cluster) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:cluster_projects) }
  it { is_expected.to have_many(:projects) }
  it { is_expected.to have_many(:cluster_groups) }
  it { is_expected.to have_many(:groups) }
  it { is_expected.to have_one(:provider_gcp) }
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
  it { is_expected.to delegate_method(:active?).to(:platform_kubernetes).with_prefix }
  it { is_expected.to delegate_method(:rbac?).to(:platform_kubernetes).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_helm).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_ingress).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_prometheus).with_prefix }
  it { is_expected.to delegate_method(:available?).to(:application_knative).with_prefix }
  it { is_expected.to delegate_method(:external_ip).to(:application_ingress).with_prefix }
  it { is_expected.to delegate_method(:external_hostname).to(:application_ingress).with_prefix }

  it { is_expected.to respond_to :project }

  it do
    expect(subject.knative_services_finder(subject.project))
      .to be_instance_of(Clusters::KnativeServicesFinder)
  end

  describe '.enabled' do
    subject { described_class.enabled }

    let!(:cluster) { create(:cluster, enabled: true) }

    before do
      create(:cluster, enabled: false)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.disabled' do
    subject { described_class.disabled }

    let!(:cluster) { create(:cluster, enabled: false) }

    before do
      create(:cluster, enabled: true)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.user_provided' do
    subject { described_class.user_provided }

    let!(:cluster) { create(:cluster, :provided_by_user) }

    before do
      create(:cluster, :provided_by_gcp)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.gcp_provided' do
    subject { described_class.gcp_provided }

    let!(:cluster) { create(:cluster, :provided_by_gcp) }

    before do
      create(:cluster, :provided_by_user)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe '.gcp_installed' do
    subject { described_class.gcp_installed }

    let!(:cluster) { create(:cluster, :provided_by_gcp) }

    before do
      create(:cluster, :providing_by_gcp)
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

  describe '.missing_kubernetes_namespace' do
    let!(:cluster) { create(:cluster, :provided_by_gcp, :project) }
    let(:project) { cluster.project }
    let(:kubernetes_namespaces) { project.kubernetes_namespaces }

    subject do
      described_class.joins(:projects).where(projects: { id: project.id }).missing_kubernetes_namespace(kubernetes_namespaces)
    end

    it { is_expected.to contain_exactly(cluster) }

    context 'kubernetes namespace exists' do
      before do
        create(:cluster_kubernetes_namespace, project: project, cluster: cluster)
      end

      it { is_expected.to be_empty }
    end
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
        expect(subject.class.name.deconstantize).to eq(Clusters::Providers.to_s)
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

  describe '#all_projects' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    subject { cluster.all_projects }

    context 'project cluster' do
      it 'returns project' do
        is_expected.to eq([project])
      end
    end

    context 'group cluster' do
      let(:cluster) { create(:cluster, :group) }
      let(:group) { cluster.group }
      let(:project) { create(:project, group: group) }
      let(:subgroup) { create(:group, parent: group) }
      let(:subproject) { create(:project, group: subgroup) }

      it 'returns all projects for group' do
        is_expected.to contain_exactly(project, subproject)
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
      let!(:prometheus) { create(:clusters_applications_prometheus, cluster: cluster) }
      let!(:runner) { create(:clusters_applications_runner, cluster: cluster) }
      let!(:jupyter) { create(:clusters_applications_jupyter, cluster: cluster) }
      let!(:knative) { create(:clusters_applications_knative, cluster: cluster) }

      it 'returns a list of created applications' do
        is_expected.to contain_exactly(helm, ingress, cert_manager, prometheus, runner, jupyter, knative)
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

  describe '#find_or_initialize_kubernetes_namespace_for_project' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.projects.first }

    subject { cluster.find_or_initialize_kubernetes_namespace_for_project(project) }

    context 'kubernetes namespace exists' do
      context 'with no service account token' do
        let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, project: project, cluster: cluster) }

        it { is_expected.to eq kubernetes_namespace }
      end

      context 'with a service account token' do
        let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, :with_token, project: project, cluster: cluster) }

        it { is_expected.to eq kubernetes_namespace }
      end
    end

    context 'kubernetes namespace does not exist' do
      it 'initializes a new namespace and sets default values' do
        expect(subject).to be_new_record
        expect(subject.project).to eq project
        expect(subject.cluster).to eq cluster
        expect(subject.namespace).to be_present
        expect(subject.service_account_name).to be_present
      end
    end

    context 'a custom scope is provided' do
      let(:scope) { cluster.kubernetes_namespaces.has_service_account_token }

      subject { cluster.find_or_initialize_kubernetes_namespace_for_project(project, scope: scope) }

      context 'kubernetes namespace exists' do
        context 'with no service account token' do
          let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, project: project, cluster: cluster) }

          it 'initializes a new namespace and sets default values' do
            expect(subject).to be_new_record
            expect(subject.project).to eq project
            expect(subject.cluster).to eq cluster
            expect(subject.namespace).to be_present
            expect(subject.service_account_name).to be_present
          end
        end

        context 'with a service account token' do
          let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, :with_token, project: project, cluster: cluster) }

          it { is_expected.to eq kubernetes_namespace }
        end
      end
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

      before do
        cluster.provider.make_errored!
      end

      it { is_expected.to eq :errored }
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
end
