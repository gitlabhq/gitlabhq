require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171013104327_migrate_gcp_clusters_to_new_clusters_architectures.rb')

describe MigrateGcpClustersToNewClustersArchitectures, :migration do
  let(:projects) { table(:projects) }
  let(:project) { projects.create }
  let(:users) { table(:users) }
  let(:user) { users.create! }
  let(:service) { GcpMigrationSpec::KubernetesService.create!(project_id: project.id) }

  module GcpMigrationSpec
    class KubernetesService < ActiveRecord::Base
      self.table_name = 'services'

      serialize :properties, JSON # rubocop:disable Cop/ActiveRecordSerialize

      default_value_for :active, true
      default_value_for :type, 'KubernetesService'
      default_value_for :properties, {
        api_url: 'https://kubernetes.example.com',
        token: 'a' * 40
      }
    end
  end

  context 'when cluster is being created' do
    let(:project_id) { project.id }
    let(:user_id) { user.id }
    let(:service_id) { service.id }
    let(:status) { 2 } # creating
    let(:gcp_cluster_size) { 1 }
    let(:created_at) { "'2017-10-17 20:24:02'" }
    let(:updated_at) { "'2017-10-17 20:28:44'" }
    let(:enabled) { true }
    let(:status_reason) { "''" }
    let(:project_namespace) { "'sample-app'" }
    let(:endpoint) { 'NULL' }
    let(:ca_cert) { 'NULL' }
    let(:encrypted_kubernetes_token) { 'NULL' }
    let(:encrypted_kubernetes_token_iv) { 'NULL' }
    let(:username) { 'NULL' }
    let(:encrypted_password) { 'NULL' }
    let(:encrypted_password_iv) { 'NULL' }
    let(:gcp_project_id) { "'gcp_project_id'" }
    let(:gcp_cluster_zone) { "'gcp_cluster_zone'" }
    let(:gcp_cluster_name) { "'gcp_cluster_name'" }
    let(:gcp_machine_type) { "'gcp_machine_type'" }
    let(:gcp_operation_id) { 'NULL' }
    let(:encrypted_gcp_token) { "'encrypted_gcp_token'" }
    let(:encrypted_gcp_token_iv) { "'encrypted_gcp_token_iv'" }

    let(:cluster) { described_class::Cluster.last }
    let(:cluster_id) { cluster.id }

    before do
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO gcp_clusters (project_id, user_id, service_id, status, gcp_cluster_size, created_at, updated_at, enabled, status_reason, project_namespace, endpoint, ca_cert, encrypted_kubernetes_token, encrypted_kubernetes_token_iv, username, encrypted_password, encrypted_password_iv, gcp_project_id, gcp_cluster_zone, gcp_cluster_name, gcp_machine_type, gcp_operation_id, encrypted_gcp_token, encrypted_gcp_token_iv)
        VALUES (#{project_id}, #{user_id}, #{service_id}, #{status}, #{gcp_cluster_size}, #{created_at}, #{updated_at}, #{enabled}, #{status_reason}, #{project_namespace}, #{endpoint}, #{ca_cert}, #{encrypted_kubernetes_token}, #{encrypted_kubernetes_token_iv}, #{username}, #{encrypted_password}, #{encrypted_password_iv}, #{gcp_project_id}, #{gcp_cluster_zone}, #{gcp_cluster_name}, #{gcp_machine_type}, #{gcp_operation_id}, #{encrypted_gcp_token}, #{encrypted_gcp_token_iv});
      SQL
    end

    it 'correctly migrate to new clusters architectures' do
      migrate!

      expect(described_class::Cluster.count).to eq(1)
      expect(described_class::ClustersProject.count).to eq(1)
      expect(described_class::ProvidersGcp.count).to eq(1)
      expect(described_class::PlatformsKubernetes.count).to eq(1)

      expect(cluster.user_id).to eq(user.id)
      expect(cluster.enabled).to be_truthy
      expect(cluster.name).to eq(gcp_cluster_name.delete!("'"))
      expect(cluster.provider_type).to eq('gcp')
      expect(cluster.platform_type).to eq('kubernetes')

      expect(cluster.project_ids).to include(project.id)

      expect(cluster.provider_gcp.cluster_id).to eq(cluster.id)
      expect(cluster.provider_gcp.status).to eq(status)
      expect(cluster.provider_gcp.status_reason).to eq(tr(status_reason))
      expect(cluster.provider_gcp.gcp_project_id).to eq(tr(gcp_project_id))
      expect(cluster.provider_gcp.zone).to eq(tr(gcp_cluster_zone))
      expect(cluster.provider_gcp.num_nodes).to eq(gcp_cluster_size)
      expect(cluster.provider_gcp.machine_type).to eq(tr(gcp_machine_type))
      expect(cluster.provider_gcp.operation_id).to be_nil
      expect(cluster.provider_gcp.endpoint).to be_nil
      expect(cluster.provider_gcp.encrypted_access_token).to eq(tr(encrypted_gcp_token))
      expect(cluster.provider_gcp.encrypted_access_token_iv).to eq(tr(encrypted_gcp_token_iv))

      expect(cluster.platform_kubernetes.cluster_id).to eq(cluster.id)
      expect(cluster.platform_kubernetes.api_url).to be_nil
      expect(cluster.platform_kubernetes.ca_cert).to be_nil
      expect(cluster.platform_kubernetes.namespace).to eq(tr(project_namespace))
      expect(cluster.platform_kubernetes.username).to be_nil
      expect(cluster.platform_kubernetes.encrypted_password).to be_nil
      expect(cluster.platform_kubernetes.encrypted_password_iv).to be_nil
      expect(cluster.platform_kubernetes.encrypted_token).to be_nil
      expect(cluster.platform_kubernetes.encrypted_token_iv).to be_nil
    end
  end

  context 'when cluster has been created' do
    let(:project_id) { project.id }
    let(:user_id) { user.id }
    let(:service_id) { service.id }
    let(:status) { 3 } # created
    let(:gcp_cluster_size) { 1 }
    let(:created_at) { "'2017-10-17 20:24:02'" }
    let(:updated_at) { "'2017-10-17 20:28:44'" }
    let(:enabled) { true }
    let(:status_reason) { "'general error'" }
    let(:project_namespace) { "'sample-app'" }
    let(:endpoint) { "'111.111.111.111'" }
    let(:ca_cert) { "'ca_cert'" }
    let(:encrypted_kubernetes_token) { "'encrypted_kubernetes_token'" }
    let(:encrypted_kubernetes_token_iv) { "'encrypted_kubernetes_token_iv'" }
    let(:username) { "'username'" }
    let(:encrypted_password) { "'encrypted_password'" }
    let(:encrypted_password_iv) { "'encrypted_password_iv'" }
    let(:gcp_project_id) { "'gcp_project_id'" }
    let(:gcp_cluster_zone) { "'gcp_cluster_zone'" }
    let(:gcp_cluster_name) { "'gcp_cluster_name'" }
    let(:gcp_machine_type) { "'gcp_machine_type'" }
    let(:gcp_operation_id) { "'gcp_operation_id'" }
    let(:encrypted_gcp_token) { "'encrypted_gcp_token'" }
    let(:encrypted_gcp_token_iv) { "'encrypted_gcp_token_iv'" }

    let(:cluster) { described_class::Cluster.last }
    let(:cluster_id) { cluster.id }

    before do
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO gcp_clusters (project_id, user_id, service_id, status, gcp_cluster_size, created_at, updated_at, enabled, status_reason, project_namespace, endpoint, ca_cert, encrypted_kubernetes_token, encrypted_kubernetes_token_iv, username, encrypted_password, encrypted_password_iv, gcp_project_id, gcp_cluster_zone, gcp_cluster_name, gcp_machine_type, gcp_operation_id, encrypted_gcp_token, encrypted_gcp_token_iv)
        VALUES (#{project_id}, #{user_id}, #{service_id}, #{status}, #{gcp_cluster_size}, #{created_at}, #{updated_at}, #{enabled}, #{status_reason}, #{project_namespace}, #{endpoint}, #{ca_cert}, #{encrypted_kubernetes_token}, #{encrypted_kubernetes_token_iv}, #{username}, #{encrypted_password}, #{encrypted_password_iv}, #{gcp_project_id}, #{gcp_cluster_zone}, #{gcp_cluster_name}, #{gcp_machine_type}, #{gcp_operation_id}, #{encrypted_gcp_token}, #{encrypted_gcp_token_iv});
      SQL
    end

    it 'correctly migrate to new clusters architectures' do
      migrate!

      expect(described_class::Cluster.count).to eq(1)
      expect(described_class::ClustersProject.count).to eq(1)
      expect(described_class::ProvidersGcp.count).to eq(1)
      expect(described_class::PlatformsKubernetes.count).to eq(1)

      expect(cluster.user_id).to eq(user.id)
      expect(cluster.enabled).to be_truthy
      expect(cluster.name).to eq(tr(gcp_cluster_name))
      expect(cluster.provider_type).to eq('gcp')
      expect(cluster.platform_type).to eq('kubernetes')

      expect(cluster.project_ids).to include(project.id)

      expect(cluster.provider_gcp.cluster_id).to eq(cluster.id)
      expect(cluster.provider_gcp.status).to eq(status)
      expect(cluster.provider_gcp.status_reason).to eq(tr(status_reason))
      expect(cluster.provider_gcp.gcp_project_id).to eq(tr(gcp_project_id))
      expect(cluster.provider_gcp.zone).to eq(tr(gcp_cluster_zone))
      expect(cluster.provider_gcp.num_nodes).to eq(gcp_cluster_size)
      expect(cluster.provider_gcp.machine_type).to eq(tr(gcp_machine_type))
      expect(cluster.provider_gcp.operation_id).to eq(tr(gcp_operation_id))
      expect(cluster.provider_gcp.endpoint).to eq(tr(endpoint))
      expect(cluster.provider_gcp.encrypted_access_token).to eq(tr(encrypted_gcp_token))
      expect(cluster.provider_gcp.encrypted_access_token_iv).to eq(tr(encrypted_gcp_token_iv))

      expect(cluster.platform_kubernetes.cluster_id).to eq(cluster.id)
      expect(cluster.platform_kubernetes.api_url).to eq('https://' + tr(endpoint))
      expect(cluster.platform_kubernetes.ca_cert).to eq(tr(ca_cert))
      expect(cluster.platform_kubernetes.namespace).to eq(tr(project_namespace))
      expect(cluster.platform_kubernetes.username).to eq(tr(username))
      expect(cluster.platform_kubernetes.encrypted_password).to eq(tr(encrypted_password))
      expect(cluster.platform_kubernetes.encrypted_password_iv).to eq(tr(encrypted_password_iv))
      expect(cluster.platform_kubernetes.encrypted_token).to eq(tr(encrypted_kubernetes_token))
      expect(cluster.platform_kubernetes.encrypted_token_iv).to eq(tr(encrypted_kubernetes_token_iv))
    end
  end

  def tr(s)
    s.delete("'")
  end
end
