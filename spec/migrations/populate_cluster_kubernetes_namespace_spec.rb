# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181009205043_populate_cluster_kubernetes_namespace.rb')

describe PopulateClusterKubernetesNamespace, :sidekiq, :migration do
  let(:table_namespaces) { table(:namespaces) }
  let(:table_projects) { table(:projects) }
  let(:table_clusters) { table(:clusters) }
  let(:table_platform_kubernetes) { table(:cluster_platforms_kubernetes) }
  let(:table_cluster_projects) { table(:cluster_projects) }
  let(:table_cluster_kubernetes_namespaces) { table(:clusters_kubernetes_namespaces) }
  let(:namespace) { table_namespaces.create!(name: 'gitlab', path: 'gitlab_namespace') }

  let(:projects) do
    (1..10).each_with_object([]) do |n, array|
      project = table_projects.create(id: n, name: "project_#{n}", path: "gitlab_#{n}", namespace_id: namespace.id)
      array << project
    end
  end

  describe '#up' do
    before do
      projects.each do |project|
        create_cluster_structure(project)
      end
    end

    it 'schedules delayed background migrations in batches' do
      Sidekiq::Testing.fake! do
        Timecop.freeze do
          expect(Clusters::KubernetesNamespace.count).to eq(0)

          migrate!

          first_cluster_project = Project.first.cluster_project
          last_cluster_project = Project.last.cluster_project

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(5.minutes, first_cluster_project.id, last_cluster_project.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(1)
        end
      end
    end
  end

  def create_cluster_structure(project, kubernetes_namespace: false)
    cluster = table_clusters.create!(name: "cluster_#{project.id}", platform_type: :kubernetes, provider_type: :user)
    table_platform_kubernetes.create!(api_url: 'https://sample.kubernetes.com', ca_cert: 'ca_pem_sample', encrypted_token: 'token_sample', cluster_id: cluster.id)
    table_cluster_projects.create!(cluster_id: cluster.id, project_id: project.id)
  end
end
