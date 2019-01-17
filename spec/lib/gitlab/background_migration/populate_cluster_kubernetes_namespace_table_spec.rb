# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
describe Gitlab::BackgroundMigration::PopulateClusterKubernetesNamespaceTable, :migration, schema: 20181022173835 do
  let(:migration) { described_class.new }
  let(:clusters) { create_list(:cluster, 10, :project, :provided_by_gcp) }

  before do
    clusters
  end

  shared_examples 'consistent kubernetes namespace attributes' do
    it 'should populate namespace and service account information' do
      subject

      clusters_with_namespace.each do |cluster|
        project = cluster.project
        cluster_project = cluster.cluster_projects.first
        namespace = "#{project.path}-#{project.id}"
        kubernetes_namespace = cluster.reload.kubernetes_namespace

        expect(kubernetes_namespace).to be_present
        expect(kubernetes_namespace.cluster_project).to eq(cluster_project)
        expect(kubernetes_namespace.project).to eq(cluster_project.project)
        expect(kubernetes_namespace.cluster).to eq(cluster_project.cluster)
        expect(kubernetes_namespace.namespace).to eq(namespace)
        expect(kubernetes_namespace.service_account_name).to eq("#{namespace}-service-account")
      end
    end
  end

  subject { migration.perform }

  context 'when no Clusters::Project has a Clusters::KubernetesNamespace' do
    let(:cluster_projects) { Clusters::Project.all }

    it 'should create a Clusters::KubernetesNamespace per Clusters::Project' do
      expect do
        subject
      end.to change(Clusters::KubernetesNamespace, :count).by(cluster_projects.count)
    end

    it_behaves_like 'consistent kubernetes namespace attributes' do
      let(:clusters_with_namespace) { clusters }
    end
  end

  context 'when every Clusters::Project has Clusters::KubernetesNamespace' do
    before do
      clusters.each do |cluster|
        create(:cluster_kubernetes_namespace,
               cluster_project: cluster.cluster_projects.first,
               cluster: cluster,
               project: cluster.project)
      end
    end

    it 'should not create any Clusters::KubernetesNamespace' do
      expect do
        subject
      end.not_to change(Clusters::KubernetesNamespace, :count)
    end
  end

  context 'when only some Clusters::Project have Clusters::KubernetesNamespace related' do
    let(:with_kubernetes_namespace) { clusters.first(6) }
    let(:with_no_kubernetes_namespace) { clusters.last(4) }

    before do
      with_kubernetes_namespace.each do |cluster|
        create(:cluster_kubernetes_namespace,
               cluster_project: cluster.cluster_projects.first,
               cluster: cluster,
               project: cluster.project)
      end
    end

    it 'creates limited number of Clusters::KubernetesNamespace' do
      expect do
        subject
      end.to change(Clusters::KubernetesNamespace, :count).by(with_no_kubernetes_namespace.count)
    end

    it 'should not modify clusters with Clusters::KubernetesNamespace' do
      subject

      with_kubernetes_namespace.each do |cluster|
        expect(cluster.kubernetes_namespaces.count).to eq(1)
      end
    end

    it_behaves_like 'consistent kubernetes namespace attributes' do
      let(:clusters_with_namespace) { with_no_kubernetes_namespace }
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
