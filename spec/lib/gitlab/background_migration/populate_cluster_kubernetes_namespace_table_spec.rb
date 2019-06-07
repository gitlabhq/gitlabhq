# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateClusterKubernetesNamespaceTable, :migration, schema: 20181022173835 do
  include MigrationHelpers::ClusterHelpers

  let(:migration) { described_class.new }
  let(:clusters_table) { table(:clusters) }
  let(:cluster_projects_table) { table(:cluster_projects) }
  let(:cluster_kubernetes_namespaces_table) { table(:clusters_kubernetes_namespaces) }
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:provider_gcp_table) { table(:cluster_providers_gcp) }
  let(:platform_kubernetes_table) { table(:cluster_platforms_kubernetes) }

  before do
    create_cluster_project_list(10)
  end

  shared_examples 'consistent kubernetes namespace attributes' do
    it 'populates namespace and service account information' do
      migration.perform

      clusters_with_namespace.each do |cluster|
        cluster_project = cluster_projects_table.find_by(cluster_id: cluster.id)
        project = projects_table.find(cluster_project.project_id)
        kubernetes_namespace = cluster_kubernetes_namespaces_table.find_by(cluster_id: cluster.id)
        namespace = "#{project.path}-#{project.id}"

        expect(kubernetes_namespace).to be_present
        expect(kubernetes_namespace.cluster_project_id).to eq(cluster_project.id)
        expect(kubernetes_namespace.project_id).to eq(cluster_project.project_id)
        expect(kubernetes_namespace.cluster_id).to eq(cluster_project.cluster_id)
        expect(kubernetes_namespace.namespace).to eq(namespace)
        expect(kubernetes_namespace.service_account_name).to eq("#{namespace}-service-account")
      end
    end
  end

  context 'when no Clusters::Project has a Clusters::KubernetesNamespace' do
    let(:cluster_projects) { cluster_projects_table.all }

    it 'creates a Clusters::KubernetesNamespace per Clusters::Project' do
      expect do
        migration.perform
      end.to change(Clusters::KubernetesNamespace, :count).by(cluster_projects_table.count)
    end

    it_behaves_like 'consistent kubernetes namespace attributes' do
      let(:clusters_with_namespace) { clusters_table.all }
    end
  end

  context 'when every Clusters::Project has Clusters::KubernetesNamespace' do
    before do
      create_kubernetes_namespace(clusters_table.all)
    end

    it 'does not create any Clusters::KubernetesNamespace' do
      expect do
        migration.perform
      end.not_to change(Clusters::KubernetesNamespace, :count)
    end
  end

  context 'when only some Clusters::Project have Clusters::KubernetesNamespace related' do
    let(:with_kubernetes_namespace) { clusters_table.first(6) }
    let(:with_no_kubernetes_namespace) { clusters_table.last(4) }

    before do
      create_kubernetes_namespace(with_kubernetes_namespace)
    end

    it 'creates limited number of Clusters::KubernetesNamespace' do
      expect do
        migration.perform
      end.to change(Clusters::KubernetesNamespace, :count).by(with_no_kubernetes_namespace.count)
    end

    it 'does not modify clusters with Clusters::KubernetesNamespace' do
      migration.perform

      with_kubernetes_namespace.each do |cluster|
        kubernetes_namespace = cluster_kubernetes_namespaces_table.where(cluster_id: cluster.id)
        expect(kubernetes_namespace.count).to eq(1)
      end
    end

    it_behaves_like 'consistent kubernetes namespace attributes' do
      let(:clusters_with_namespace) { with_no_kubernetes_namespace }
    end
  end
end
