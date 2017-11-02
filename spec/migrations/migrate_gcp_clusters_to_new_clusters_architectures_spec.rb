require 'spec_helper'
require Rails.root.join('db', 'migrate', '20171013104327_migrate_gcp_clusters_to_new_clusters_architectures.rb')

describe MigrateGcpClustersToNewClustersArchitectures, :migration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { create(:kubernetes_service, project: project) }

  let(:project_id) { project.id }
  let(:user_id) { user.id }
  let(:service_id) { service.id }
  let(:status) { 3 }
  let(:gcp_cluster_size) { 1 }
  let(:created_at) { '2017-10-17 20:24:02.219679' }
  let(:updated_at) { '2017-10-17 20:28:44.738998' }
  let(:enabled) { true }
  let(:status_reason) { 'general error' }
  let(:project_namespace) { 'sample-app' }
  let(:endpoint) { '111.111.111.111' }
  let(:ca_cert) { 'ca_cert' }
  let(:encrypted_kubernetes_token) { 'encrypted_kubernetes_token' }
  let(:encrypted_kubernetes_token_iv) { 'encrypted_kubernetes_token_iv' }
  let(:username) { 'username' }
  let(:encrypted_password) { 'encrypted_password' }
  let(:encrypted_password_iv) { 'encrypted_password_iv' }
  let(:gcp_project_id) { 'gcp_project_id' }
  let(:gcp_cluster_zone) { 'gcp_cluster_zone' }
  let(:gcp_cluster_name) { 'gcp_cluster_name' }
  let(:gcp_machine_type) { 'gcp_machine_type' }
  let(:gcp_operation_id) { 'gcp_operation_id' }
  let(:encrypted_gcp_token) { 'encrypted_gcp_token' }
  let(:encrypted_gcp_token_iv) { 'encrypted_gcp_token_iv' }

  let(:cluster) { Clusters::Cluster.last }
  let(:cluster_id) { cluster.id }

  before do
    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO gcp_clusters (project_id, user_id, service_id, status, gcp_cluster_size, created_at, updated_at, enabled, status_reason, project_namespace, endpoint, ca_cert, encrypted_kubernetes_token, encrypted_kubernetes_token_iv, username, encrypted_password, encrypted_password_iv, gcp_project_id, gcp_cluster_zone, gcp_cluster_name, gcp_machine_type, gcp_operation_id, encrypted_gcp_token, encrypted_gcp_token_iv)
      VALUES ('#{project_id}', '#{user_id}', '#{service_id}', '#{status}', '#{gcp_cluster_size}', '#{created_at}', '#{updated_at}', '#{enabled}', '#{status_reason}', '#{project_namespace}', '#{endpoint}', '#{ca_cert}', '#{encrypted_kubernetes_token}', '#{encrypted_kubernetes_token_iv}', '#{username}', '#{encrypted_password}', '#{encrypted_password_iv}', '#{gcp_project_id}', '#{gcp_cluster_zone}', '#{gcp_cluster_name}', '#{gcp_machine_type}', '#{gcp_operation_id}', '#{encrypted_gcp_token}', '#{encrypted_gcp_token_iv}');
    SQL
  end

  it 'correctly migrate to new clusters architectures' do
    migrate!

    expect(Clusters::Cluster.count).to eq(1)
    expect(Clusters::Project.count).to eq(1)
    expect(Clusters::Providers::Gcp.count).to eq(1)
    expect(Clusters::Platforms::Kubernetes.count).to eq(1)

    expect(cluster.user).to eq(user)
    expect(cluster.enabled).to eq(enabled)
    expect(cluster.name).to eq(gcp_cluster_name)
    expect(cluster.provider_type).to eq('gcp')
    expect(cluster.platform_type).to eq('kubernetes')
    expect(cluster.created_at).to eq(created_at)
    expect(cluster.updated_at).to eq(updated_at)

    expect(cluster.project).to eq(project)

    expect(cluster.provider_gcp.cluster).to eq(cluster)
    expect(cluster.provider_gcp.status).to eq(status)
    expect(cluster.provider_gcp.status_reason).to eq(status_reason)
    expect(cluster.provider_gcp.gcp_project_id).to eq(gcp_project_id)
    expect(cluster.provider_gcp.zone).to eq(gcp_cluster_zone)
    expect(cluster.provider_gcp.num_nodes).to eq(gcp_cluster_size)
    expect(cluster.provider_gcp.machine_type).to eq(gcp_machine_type)
    expect(cluster.provider_gcp.operation_id).to eq(gcp_operation_id)
    expect(cluster.provider_gcp.endpoint).to eq(endpoint)
    expect(cluster.provider_gcp.encrypted_access_token).to eq(encrypted_gcp_token)
    expect(cluster.provider_gcp.encrypted_access_token_iv).to eq(encrypted_gcp_token_iv)
    expect(cluster.provider_gcp.created_at).to eq(created_at)
    expect(cluster.provider_gcp.updated_at).to eq(updated_at)

    expect(cluster.platform_kubernetes.cluster).to eq(cluster)
    expect(cluster.platform_kubernetes.api_url).to eq('https://' + endpoint)
    expect(cluster.platform_kubernetes.ca_cert).to eq(ca_cert)
    expect(cluster.platform_kubernetes.namespace).to eq(project_namespace)
    expect(cluster.platform_kubernetes.username).to eq(username)
    expect(cluster.platform_kubernetes.encrypted_password).to eq(encrypted_password)
    expect(cluster.platform_kubernetes.encrypted_password_iv).to eq(encrypted_password_iv)
    expect(cluster.platform_kubernetes.encrypted_token).to eq(encrypted_kubernetes_token)
    expect(cluster.platform_kubernetes.encrypted_token_iv).to eq(encrypted_kubernetes_token_iv)
    expect(cluster.platform_kubernetes.created_at).to eq(created_at)
    expect(cluster.platform_kubernetes.updated_at).to eq(updated_at)
  end
end
