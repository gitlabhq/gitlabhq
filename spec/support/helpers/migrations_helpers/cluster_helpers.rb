# frozen_string_literal: true

module MigrationHelpers
  module ClusterHelpers
    # Creates a list of cluster projects.
    def create_cluster_project_list(quantity)
      group = namespaces_table.create!(name: 'gitlab-org', path: 'gitlab-org')

      quantity.times do |id|
        create_cluster_project(group, id)
      end
    end

    # Creates dependencies for a cluster project:
    # - Group
    # - Project
    # - Cluster
    # - Project - cluster relationship
    # - GCP provider
    # - Platform Kubernetes
    def create_cluster_project(group, id)
      project = projects_table.create!(
        name: "project-#{id}",
        path: "project-#{id}",
        namespace_id: group.id
      )

      cluster = clusters_table.create!(
        name: 'test-cluster',
        cluster_type: 3,
        provider_type: :gcp,
        platform_type: :kubernetes
      )

      cluster_projects_table.create!(project_id: project.id, cluster_id: cluster.id)

      provider_gcp_table.create!(
        gcp_project_id: "test-gcp-project-#{id}",
        endpoint: '111.111.111.111',
        cluster_id: cluster.id,
        status: 3,
        num_nodes: 1,
        zone: 'us-central1-a'
      )

      platform_kubernetes_table.create!(
        cluster_id: cluster.id,
        api_url: 'https://kubernetes.example.com',
        encrypted_token: 'a' * 40,
        encrypted_token_iv: 'a' * 40
      )
    end

    # Creates a Kubernetes namespace for a list of clusters
    def create_kubernetes_namespace(clusters)
      clusters.each do |cluster|
        cluster_project = cluster_projects_table.find_by(cluster_id: cluster.id)
        project = projects_table.find(cluster_project.project_id)
        namespace = "#{project.path}-#{project.id}"

        cluster_kubernetes_namespaces_table.create!(
          cluster_project_id: cluster_project.id,
          cluster_id: cluster.id,
          project_id: cluster_project.project_id,
          namespace: namespace,
          service_account_name: "#{namespace}-service-account"
        )
      end
    end
  end
end
