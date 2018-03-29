module KubernetesHelpers
  include Gitlab::Kubernetes

  def kube_response(body)
    { body: body.to_json }
  end

  def kube_pods_response
    kube_response(kube_pods_body)
  end

  def kube_deployments_response
    kube_response(kube_deployments_body)
  end

  def stub_kubeclient_discover(api_url)
    WebMock.stub_request(:get, api_url + '/api/v1').to_return(kube_response(kube_v1_discovery_body))
    WebMock.stub_request(:get, api_url + '/apis/extensions/v1beta1').to_return(kube_response(kube_v1beta1_discovery_body))
  end

  def stub_kubeclient_pods(response = nil)
    stub_kubeclient_discover(service.api_url)
    pods_url = service.api_url + "/api/v1/namespaces/#{service.actual_namespace}/pods"

    WebMock.stub_request(:get, pods_url).to_return(response || kube_pods_response)
  end

  def stub_kubeclient_deployments(response = nil)
    stub_kubeclient_discover(service.api_url)
    deployments_url = service.api_url + "/apis/extensions/v1beta1/namespaces/#{service.actual_namespace}/deployments"

    WebMock.stub_request(:get, deployments_url).to_return(response || kube_deployments_response)
  end

  def stub_kubeclient_get_secrets(api_url, **options)
    WebMock.stub_request(:get, api_url + '/api/v1/secrets')
      .to_return(kube_response(kube_v1_secrets_body(options)))
  end

  def stub_kubeclient_get_secrets_error(api_url)
    WebMock.stub_request(:get, api_url + '/api/v1/secrets')
      .to_return(status: [404, "Internal Server Error"])
  end

  def kube_v1_secrets_body(**options)
    {
      "kind" => "SecretList",
      "apiVersion": "v1",
      "items" => [
        {
          "metadata": {
            "name": options[:metadata_name] || "default-token-1",
            "namespace": "kube-system"
          },
          "data": {
            "token": options[:token] || Base64.encode64('token-sample-123')
          }
        }
      ]
    }
  end

  def kube_v1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "pods", "namespaced" => true, "kind" => "Pod" },
        { "name" => "deployments", "namespaced" => true, "kind" => "Deployment" },
        { "name" => "secrets", "namespaced" => true, "kind" => "Secret" }
      ]
    }
  end

  def kube_v1beta1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "pods", "namespaced" => true, "kind" => "Pod" },
        { "name" => "deployments", "namespaced" => true, "kind" => "Deployment" },
        { "name" => "secrets", "namespaced" => true, "kind" => "Secret" }
      ]
    }
  end

  def kube_pods_body
    {
      "kind" => "PodList",
      "items" => [kube_pod]
    }
  end

  def kube_deployments_body
    {
      "kind" => "DeploymentList",
      "items" => [kube_deployment]
    }
  end

  # This is a partial response, it will have many more elements in reality but
  # these are the ones we care about at the moment
  def kube_pod(name: "kube-pod", app: "valid-pod-label")
    {
      "metadata" => {
        "name" => name,
        "creationTimestamp" => "2016-11-25T19:55:19Z",
        "labels" => { "app" => app }
      },
      "spec" => {
        "containers" => [
          { "name" => "container-0" },
          { "name" => "container-1" }
        ]
      },
      "status" => { "phase" => "Running" }
    }
  end

  def kube_deployment(name: "kube-deployment", app: "valid-deployment-label", track: nil)
    {
      "metadata" => {
        "name" => name,
        "generation" => 4,
        "labels" => {
          "app" => app,
          "track" => track
        }.compact
      },
      "spec" => { "replicas" => 3 },
      "status" => {
        "observedGeneration" => 4,
        "replicas" => 3,
        "updatedReplicas" => 3,
        "availableReplicas" => 3
      }
    }
  end

  def kube_terminals(service, pod)
    pod_name = pod['metadata']['name']
    containers = pod['spec']['containers']

    containers.map do |container|
      terminal = {
        selectors: { pod: pod_name, container: container['name'] },
        url:  container_exec_url(service.api_url, service.actual_namespace, pod_name, container['name']),
        subprotocols: ['channel.k8s.io'],
        headers: { 'Authorization' => ["Bearer #{service.token}"] },
        created_at: DateTime.parse(pod['metadata']['creationTimestamp']),
        max_session_time: 0
      }
      terminal[:ca_pem] = service.ca_pem if service.ca_pem.present?
      terminal
    end
  end

  def kube_deployment_rollout_status
    ::Gitlab::Kubernetes::RolloutStatus.from_specs(kube_deployment)
  end

  def empty_deployment_rollout_status
    ::Gitlab::Kubernetes::RolloutStatus.from_specs()
  end
end
