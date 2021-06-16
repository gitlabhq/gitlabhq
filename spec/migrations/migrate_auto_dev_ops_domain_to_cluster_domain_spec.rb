# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateAutoDevOpsDomainToClusterDomain do
  include MigrationHelpers::ClusterHelpers

  let(:migration) { described_class.new }
  let(:project_auto_devops_table) { table(:project_auto_devops) }
  let(:clusters_table) { table(:clusters) }
  let(:cluster_projects_table) { table(:cluster_projects) }

  # Following lets are needed by MigrationHelpers::ClusterHelpers
  let(:cluster_kubernetes_namespaces_table) { table(:clusters_kubernetes_namespaces) }
  let(:projects_table) { table(:projects) }
  let(:namespaces_table) { table(:namespaces) }
  let(:provider_gcp_table) { table(:cluster_providers_gcp) }
  let(:platform_kubernetes_table) { table(:cluster_platforms_kubernetes) }

  before do
    setup_cluster_projects_with_domain(quantity: 20, domain: domain)
  end

  context 'with ProjectAutoDevOps with no domain' do
    let(:domain) { nil }

    it 'does not update cluster project' do
      migrate!

      expect(clusters_without_domain.count).to eq(clusters_table.count)
    end
  end

  context 'with ProjectAutoDevOps with domain' do
    let(:domain) { 'example-domain.com' }

    it 'updates all cluster projects' do
      migrate!

      expect(clusters_with_domain.count).to eq(clusters_table.count)
    end
  end

  context 'when only some ProjectAutoDevOps have domain set' do
    let(:domain) { 'example-domain.com' }

    before do
      setup_cluster_projects_with_domain(quantity: 25, domain: nil)
    end

    it 'only updates specific cluster projects' do
      migrate!

      expect(clusters_with_domain.count).to eq(20)

      project_auto_devops_with_domain.each do |project_auto_devops|
        cluster_project = find_cluster_project(project_auto_devops.project_id)
        cluster = find_cluster(cluster_project.cluster_id)

        expect(cluster.domain).to be_present
      end

      expect(clusters_without_domain.count).to eq(25)

      project_auto_devops_without_domain.each do |project_auto_devops|
        cluster_project = find_cluster_project(project_auto_devops.project_id)
        cluster = find_cluster(cluster_project.cluster_id)

        expect(cluster.domain).not_to be_present
      end
    end
  end

  def setup_cluster_projects_with_domain(quantity:, domain:)
    create_cluster_project_list(quantity)

    cluster_projects = cluster_projects_table.last(quantity)

    cluster_projects.each do |cluster_project|
      specific_domain = "#{cluster_project.id}-#{domain}" if domain

      project_auto_devops_table.create!(
        project_id: cluster_project.project_id,
        enabled: true,
        domain: specific_domain
      )
    end
  end

  def find_cluster_project(project_id)
    cluster_projects_table.find_by(project_id: project_id)
  end

  def find_cluster(cluster_id)
    clusters_table.find_by(id: cluster_id)
  end

  def project_auto_devops_with_domain
    project_auto_devops_table.where.not("domain IS NULL OR domain = ''")
  end

  def project_auto_devops_without_domain
    project_auto_devops_table.where("domain IS NULL OR domain = ''")
  end

  def clusters_with_domain
    clusters_table.where.not("domain IS NULL OR domain = ''")
  end

  def clusters_without_domain
    clusters_table.where("domain IS NULL OR domain = ''")
  end
end
