require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20171013104327_migrate_gcp_clusters_to_new_clusters_architectures.rb')
require Rails.root.join('db', 'migrate', '20171123104051_fix_cluster_platforms_kubernetes_association_mismatch.rb')

##
# See more details at https://gitlab.com/gitlab-org/gitlab-ce/issues/40478
#
describe FixClusterPlatformsKubernetesAssociationMismatch, :migration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  shared_examples 'expected behavior' do
    it 'has correct association' do
      puts "described_class.name: #{described_class.name}"
      migrate!

      Clusters::Cluster.all.each do |cluster|
        expect(cluster.platform_kubernetes.api_url).to eq(api_url(cluster.provider_gcp.endpoint))
      end
    end
  end

  context 'when user did not create a cluster before post migration has done' do
    before do
      prepare
    end

    it_behaves_like 'expected behavior'
  end

  context 'when user created a cluster before post migration has done' do
    before do
      prepare
      culprit
    end

    it_behaves_like 'expected behavior'
  end

  def prepare
    create_test_data

    MigrateGcpClustersToNewClustersArchitectures.new.up
  end

  def create_test_data
    (1..5).each do |i|
      project = create(:project)
      user = create(:user)
      service = create(:kubernetes_service, project: project)

      # Params
      project_id = create(:project).id
      user_id = create(:user).id
      service_id = service.id
      status = 3 # created
      gcp_cluster_size = 1
      created_at = "'2017-10-17 20:24:02'"
      updated_at = "'2017-10-17 20:28:44'"
      enabled = true
      status_reason = "'NULL'"
      project_namespace = "'sample-app-#{i}'"
      endpoint = "'111.111.111.#{i}'"
      ca_cert = "'ca_cert-#{i}'"
      encrypted_kubernetes_token = "'kubernetes_token-#{i}'"
      encrypted_kubernetes_token_iv = "'kubernetes_token_iv-#{i}'"
      username = "'username-#{i}'"
      encrypted_password = "'password_#{i}'"
      encrypted_password_iv = "'password_iv_#{i}'"
      gcp_project_id = "'gcp_project_id-#{i}'"
      gcp_cluster_zone = "'gcp_cluster_zone-#{i}'"
      gcp_cluster_name = "'gcp_cluster_name-#{i}'"
      gcp_machine_type = "'gcp_machine_type-#{i}'"
      gcp_operation_id = "'gcp_operation_id-#{i}'"
      encrypted_gcp_token = "'gcp_token_#{i}'"
      encrypted_gcp_token_iv = "'gcp_token_iv_#{i}'"

      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO gcp_clusters (project_id, user_id, service_id, status, gcp_cluster_size, created_at, updated_at, enabled, status_reason, project_namespace, endpoint, ca_cert, encrypted_kubernetes_token, encrypted_kubernetes_token_iv, username, encrypted_password, encrypted_password_iv, gcp_project_id, gcp_cluster_zone, gcp_cluster_name, gcp_machine_type, gcp_operation_id, encrypted_gcp_token, encrypted_gcp_token_iv)
        VALUES (#{project_id}, #{user_id}, #{service_id}, #{status}, #{gcp_cluster_size}, #{created_at}, #{updated_at}, #{enabled}, #{status_reason}, #{project_namespace}, #{endpoint}, #{ca_cert}, #{encrypted_kubernetes_token}, #{encrypted_kubernetes_token_iv}, #{username}, #{encrypted_password}, #{encrypted_password_iv}, #{gcp_project_id}, #{gcp_cluster_zone}, #{gcp_cluster_name}, #{gcp_machine_type}, #{gcp_operation_id}, #{encrypted_gcp_token}, #{encrypted_gcp_token_iv});
      SQL
    end
  end

  def culprit
    (1..5).each do |i|
      cluster = Clusters::Cluster.find_by_id(i)
      cluster.platform_kubernetes.update_attribute(:cluster_id, (i % 5) + 1)
    end
  end

  def api_url(endpoint)
    endpoint ? 'https://' + endpoint : nil
  end
end
