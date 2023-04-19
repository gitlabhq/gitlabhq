# frozen_string_literal: true

module GoogleApi
  module CloudPlatformHelpers
    def stub_google_api_validate_token
      request.session[GoogleApi::CloudPlatform::Client.session_key_for_token] = 'token'
      request.session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] = 1.hour.since.to_i.to_s
    end

    def stub_google_api_expired_token
      request.session[GoogleApi::CloudPlatform::Client.session_key_for_token] = 'token'
      request.session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] = 1.hour.ago.to_i.to_s
    end

    def stub_cloud_platform_projects_list(options)
      WebMock.stub_request(:get, cloud_platform_projects_list_url)
        .to_return(cloud_platform_response(cloud_platform_projects_body(options)))
    end

    def stub_cloud_platform_projects_get_billing_info(project_id, billing_enabled)
      WebMock.stub_request(:get, cloud_platform_projects_get_billing_info_url(project_id))
        .to_return(cloud_platform_response(cloud_platform_projects_billing_info_body(project_id, billing_enabled)))
    end

    def stub_cloud_platform_get_zone_cluster(project_id, zone, cluster_id, options = {})
      WebMock.stub_request(:get, cloud_platform_get_zone_cluster_url(project_id, zone, cluster_id))
        .to_return(cloud_platform_response(cloud_platform_cluster_body(options)))
    end

    def stub_cloud_platform_get_zone_cluster_error(project_id, zone, cluster_id)
      WebMock.stub_request(:get, cloud_platform_get_zone_cluster_url(project_id, zone, cluster_id))
        .to_return(status: [500, "Internal Server Error"])
    end

    def stub_cloud_platform_create_cluster(project_id, zone, options = {})
      WebMock.stub_request(:post, cloud_platform_create_cluster_url(project_id, zone))
        .to_return(cloud_platform_response(cloud_platform_operation_body(options)))
    end

    def stub_cloud_platform_create_cluster_error(project_id, zone)
      WebMock.stub_request(:post, cloud_platform_create_cluster_url(project_id, zone))
        .to_return(status: [500, "Internal Server Error"])
    end

    def stub_cloud_platform_get_zone_operation(project_id, zone, operation_id, options = {})
      WebMock.stub_request(:get, cloud_platform_get_zone_operation_url(project_id, zone, operation_id))
        .to_return(cloud_platform_response(cloud_platform_operation_body(options)))
    end

    def stub_cloud_platform_get_zone_operation_error(project_id, zone, operation_id)
      WebMock.stub_request(:get, cloud_platform_get_zone_operation_url(project_id, zone, operation_id))
        .to_return(status: [500, "Internal Server Error"])
    end

    def cloud_platform_projects_list_url
      "https://cloudresourcemanager.googleapis.com/v1/projects"
    end

    def cloud_platform_projects_get_billing_info_url(project_id)
      "https://cloudbilling.googleapis.com/v1/projects/#{project_id}/billingInfo"
    end

    def cloud_platform_get_zone_cluster_url(project_id, zone, cluster_id)
      "https://container.googleapis.com/v1/projects/#{project_id}/zones/#{zone}/clusters/#{cluster_id}"
    end

    def cloud_platform_create_cluster_url(project_id, zone)
      "https://container.googleapis.com/v1beta1/projects/#{project_id}/zones/#{zone}/clusters"
    end

    def cloud_platform_get_zone_operation_url(project_id, zone, operation_id)
      "https://container.googleapis.com/v1/projects/#{project_id}/zones/#{zone}/operations/#{operation_id}"
    end

    def cloud_platform_response(body)
      { status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json }
    end

    def load_sample_cert
      pem_file = File.expand_path(Rails.root.join('spec/fixtures/clusters/sample_cert.pem'))
      Base64.encode64(File.read(pem_file))
    end

    ##
    # gcloud container clusters create
    # https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.zones.clusters/create
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def cloud_platform_cluster_body(options)
      {
        name: options[:name] || 'string',
        description: options[:description] || 'string',
        initialNodeCount: options[:initialNodeCount] || 'number',
        masterAuth: {
          username: options[:username] || 'string',
          password: options[:password] || 'string',
          clusterCaCertificate: options[:clusterCaCertificate] || load_sample_cert,
          clientCertificate: options[:clientCertificate] || 'string',
          clientKey: options[:clientKey] || 'string'
        },
        loggingService: options[:loggingService] || 'string',
        monitoringService: options[:monitoringService] || 'string',
        network: options[:network] || 'string',
        clusterIpv4Cidr: options[:clusterIpv4Cidr] || 'string',
        subnetwork: options[:subnetwork] || 'string',
        enableKubernetesAlpha: options[:enableKubernetesAlpha] || 'boolean',
        labelFingerprint: options[:labelFingerprint] || 'string',
        selfLink: options[:selfLink] || 'string',
        zone: options[:zone] || 'string',
        endpoint: options[:endpoint] || 'string',
        initialClusterVersion: options[:initialClusterVersion] || 'string',
        currentMasterVersion: options[:currentMasterVersion] || 'string',
        currentNodeVersion: options[:currentNodeVersion] || 'string',
        createTime: options[:createTime] || 'string',
        status: options[:status] || 'RUNNING',
        statusMessage: options[:statusMessage] || 'string',
        nodeIpv4CidrSize: options[:nodeIpv4CidrSize] || 'number',
        servicesIpv4Cidr: options[:servicesIpv4Cidr] || 'string',
        currentNodeCount: options[:currentNodeCount] || 'number',
        expireTime: options[:expireTime] || 'string'
      }
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def cloud_platform_operation_body(options)
      {
        name: options[:name] || 'operation-1234567891234-1234567',
        zone: options[:zone] || 'us-central1-a',
        operationType: options[:operationType] || 'CREATE_CLUSTER',
        status: options[:status] || 'PENDING',
        detail: options[:detail] || 'detail',
        statusMessage: options[:statusMessage] || '',
        selfLink: options[:selfLink] || 'https://container.googleapis.com/v1/projects/123456789101/zones/us-central1-a/operations/operation-1234567891234-1234567',
        targetLink: options[:targetLink] || 'https://container.googleapis.com/v1/projects/123456789101/zones/us-central1-a/clusters/test-cluster',
        startTime: options[:startTime] || '2017-09-13T16:49:13.055601589Z',
        endTime: options[:endTime] || ''
      }
    end

    def cloud_platform_projects_body(options)
      {
        projects: [
          {
            projectNumber: options[:project_number] || "1234",
            projectId: options[:project_id] || "test-project-1234",
            lifecycleState: "ACTIVE",
            name: options[:name] || "test-project",
            createTime: "2017-12-16T01:48:29.129Z",
            parent: {
              type: "organization",
              id: "12345"
            }
          }
        ]
      }
    end

    def cloud_platform_projects_billing_info_body(project_id, billing_enabled)
      {
        name: "projects/#{project_id}/billingInfo",
        projectId: project_id.to_s,
        billingAccountName: "account-name",
        billingEnabled: billing_enabled
      }
    end
  end
end
