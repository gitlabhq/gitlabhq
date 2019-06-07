module KubernetesHelpers
  include Gitlab::Kubernetes

  def kube_response(body)
    { body: body.to_json }
  end

  def kube_pods_response
    kube_response(kube_pods_body)
  end

  def kube_logs_response
    kube_response(kube_logs_body)
  end

  def kube_deployments_response
    kube_response(kube_deployments_body)
  end

  def stub_kubeclient_discover_base(api_url)
    WebMock.stub_request(:get, api_url + '/api/v1').to_return(kube_response(kube_v1_discovery_body))
    WebMock
      .stub_request(:get, api_url + '/apis/extensions/v1beta1')
      .to_return(kube_response(kube_v1beta1_discovery_body))
    WebMock
      .stub_request(:get, api_url + '/apis/rbac.authorization.k8s.io/v1')
      .to_return(kube_response(kube_v1_rbac_authorization_discovery_body))
  end

  def stub_kubeclient_discover(api_url)
    stub_kubeclient_discover_base(api_url)

    WebMock
      .stub_request(:get, api_url + '/apis/serving.knative.dev/v1alpha1')
      .to_return(kube_response(kube_v1alpha1_serving_knative_discovery_body))
  end

  def stub_kubeclient_discover_knative_not_found(api_url)
    stub_kubeclient_discover_base(api_url)

    WebMock
      .stub_request(:get, api_url + '/apis/serving.knative.dev/v1alpha1')
      .to_return(status: [404, "Resource Not Found"])
  end

  def stub_kubeclient_service_pods(response = nil, options = {})
    stub_kubeclient_discover(service.api_url)

    namespace_path = options[:namespace].present? ? "namespaces/#{options[:namespace]}/" : ""

    pods_url = service.api_url + "/api/v1/#{namespace_path}pods"

    WebMock.stub_request(:get, pods_url).to_return(response || kube_pods_response)
  end

  def stub_kubeclient_pods(namespace, status: nil)
    stub_kubeclient_discover(service.api_url)
    pods_url = service.api_url + "/api/v1/namespaces/#{namespace}/pods"
    response = { status: status } if status

    WebMock.stub_request(:get, pods_url).to_return(response || kube_pods_response)
  end

  def stub_kubeclient_logs(pod_name, namespace, status: nil)
    stub_kubeclient_discover(service.api_url)
    logs_url = service.api_url + "/api/v1/namespaces/#{namespace}/pods/#{pod_name}/log?tailLines=#{Clusters::Platforms::Kubernetes::LOGS_LIMIT}"
    response = { status: status } if status

    WebMock.stub_request(:get, logs_url).to_return(response || kube_logs_response)
  end

  def stub_kubeclient_deployments(namespace, status: nil)
    stub_kubeclient_discover(service.api_url)
    deployments_url = service.api_url + "/apis/extensions/v1beta1/namespaces/#{namespace}/deployments"
    response = { status: status } if status

    WebMock.stub_request(:get, deployments_url).to_return(response || kube_deployments_response)
  end

  def stub_kubeclient_knative_services(options = {})
    namespace_path = options[:namespace].present? ? "namespaces/#{options[:namespace]}/" : ""

    options[:name] ||= "kubetest"
    options[:domain] ||= "example.com"
    options[:response] ||= kube_response(kube_knative_services_body(options))

    stub_kubeclient_discover(service.api_url)

    knative_url = service.api_url + "/apis/serving.knative.dev/v1alpha1/#{namespace_path}services"

    WebMock.stub_request(:get, knative_url).to_return(options[:response])
  end

  def stub_kubeclient_get_secret(api_url, **options)
    options[:metadata_name] ||= "default-token-1"
    options[:namespace] ||= "default"

    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{options[:namespace]}/secrets/#{options[:metadata_name]}")
      .to_return(kube_response(kube_v1_secret_body(options)))
  end

  def stub_kubeclient_get_secret_error(api_url, name, namespace: 'default', status: 404)
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}/secrets/#{name}")
      .to_return(status: [status, "Internal Server Error"])
  end

  def stub_kubeclient_get_service_account(api_url, name, namespace: 'default')
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_service_account_error(api_url, name, namespace: 'default', status: 404)
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts/#{name}")
      .to_return(status: [status, "Internal Server Error"])
  end

  def stub_kubeclient_create_service_account(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_create_service_account_error(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts")
      .to_return(status: [500, "Internal Server Error"])
  end

  def stub_kubeclient_put_service_account(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_create_secret(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces/#{namespace}/secrets")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_put_secret(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/api/v1/namespaces/#{namespace}/secrets/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_cluster_role_binding_error(api_url, name, status: 404)
    WebMock.stub_request(:get, api_url + "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings/#{name}")
      .to_return(status: [status, "Internal Server Error"])
  end

  def stub_kubeclient_create_cluster_role_binding(api_url)
    WebMock.stub_request(:post, api_url + '/apis/rbac.authorization.k8s.io/v1/clusterrolebindings')
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_role_binding(api_url, name, namespace: 'default')
    WebMock.stub_request(:get, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_role_binding_error(api_url, name, namespace: 'default', status: 404)
    WebMock.stub_request(:get, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings/#{name}")
      .to_return(status: [status, "Internal Server Error"])
  end

  def stub_kubeclient_create_role_binding(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_put_role_binding(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_create_namespace(api_url)
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_namespace(api_url, namespace: 'default')
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}")
      .to_return(kube_response({}))
  end

  def kube_v1_secret_body(**options)
    {
      "kind" => "SecretList",
      "apiVersion": "v1",
      "metadata": {
        "name": options[:metadata_name] || "default-token-1",
        "namespace": "kube-system"
      },
      "data": {
        "token": options[:token] || Base64.encode64('token-sample-123')
      }
    }
  end

  def kube_v1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "pods", "namespaced" => true, "kind" => "Pod" },
        { "name" => "deployments", "namespaced" => true, "kind" => "Deployment" },
        { "name" => "secrets", "namespaced" => true, "kind" => "Secret" },
        { "name" => "serviceaccounts", "namespaced" => true, "kind" => "ServiceAccount" },
        { "name" => "services", "namespaced" => true, "kind" => "Service" },
        { "name" => "namespaces", "namespaced" => true, "kind" => "Namespace" }
      ]
    }
  end

  def kube_v1beta1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "pods", "namespaced" => true, "kind" => "Pod" },
        { "name" => "deployments", "namespaced" => true, "kind" => "Deployment" },
        { "name" => "secrets", "namespaced" => true, "kind" => "Secret" },
        { "name" => "serviceaccounts", "namespaced" => true, "kind" => "ServiceAccount" },
        { "name" => "services", "namespaced" => true, "kind" => "Service" }
      ]
    }
  end

  def kube_v1_rbac_authorization_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "clusterrolebindings", "namespaced" => false, "kind" => "ClusterRoleBinding" },
        { "name" => "clusterroles", "namespaced" => false, "kind" => "ClusterRole" },
        { "name" => "rolebindings", "namespaced" => true, "kind" => "RoleBinding" },
        { "name" => "roles", "namespaced" => true, "kind" => "Role" }
      ]
    }
  end

  def kube_v1alpha1_serving_knative_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "revisions", "namespaced" => true, "kind" => "Revision" },
        { "name" => "services", "namespaced" => true, "kind" => "Service" },
        { "name" => "configurations", "namespaced" => true, "kind" => "Configuration" },
        { "name" => "routes", "namespaced" => true, "kind" => "Route" }
      ]
    }
  end

  def kube_pods_body
    {
      "kind" => "PodList",
      "items" => [kube_pod]
    }
  end

  def kube_logs_body
    "Log 1\nLog 2\nLog 3"
  end

  def kube_deployments_body
    {
      "kind" => "DeploymentList",
      "items" => [kube_deployment]
    }
  end

  def kube_knative_pods_body(name, namespace)
    {
      "kind" => "PodList",
      "items" => [kube_knative_pod(name: name, namespace: namespace)]
    }
  end

  def kube_knative_services_body(**options)
    {
      "kind" => "List",
      "items" => [kube_service(options)]
    }
  end

  # This is a partial response, it will have many more elements in reality but
  # these are the ones we care about at the moment
  def kube_pod(name: "kube-pod", environment_slug: "production", namespace: "project-namespace", project_slug: "project-path-slug", status: "Running", track: nil)
    {
      "metadata" => {
        "name" => name,
        "namespace" => namespace,
        "generate_name" => "generated-name-with-suffix",
        "creationTimestamp" => "2016-11-25T19:55:19Z",
        "annotations" => {
          "app.gitlab.com/env" => environment_slug,
          "app.gitlab.com/app" => project_slug
        },
        "labels" => {
          "track" => track
        }.compact
      },
      "spec" => {
        "containers" => [
          { "name" => "container-0" },
          { "name" => "container-1" }
        ]
      },
      "status" => { "phase" => status }
    }
  end

  # Similar to a kube_pod, but should contain a running service
  def kube_knative_pod(name: "kube-pod", namespace: "default", status: "Running")
    {
      "metadata" => {
        "name" => name,
        "namespace" => namespace,
        "generate_name" => "generated-name-with-suffix",
        "creationTimestamp" => "2016-11-25T19:55:19Z",
        "labels" => {
          "serving.knative.dev/service" => name
        }
      },
      "spec" => {
        "containers" => [
          { "name" => "container-0" },
          { "name" => "container-1" }
        ]
      },
      "status" => { "phase" => status }
    }
  end

  def kube_deployment(name: "kube-deployment", environment_slug: "production", project_slug: "project-path-slug", track: nil)
    {
      "metadata" => {
        "name" => name,
        "generation" => 4,
        "annotations" => {
          "app.gitlab.com/env" => environment_slug,
          "app.gitlab.com/app" => project_slug
        },
        "labels" => {
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

  def kube_service(name: "kubetest", namespace: "default", domain: "example.com")
    {
      "metadata" => {
        "creationTimestamp" => "2018-11-21T06:16:33Z",
        "name" => name,
        "namespace" => namespace,
        "selfLink" => "/apis/serving.knative.dev/v1alpha1/namespaces/#{namespace}/services/#{name}"
      },
      "spec" => {
        "generation" => 2
      },
      "status" => {
        "domain" => "#{name}.#{namespace}.#{domain}",
        "domainInternal" => "#{name}.#{namespace}.svc.cluster.local",
        "latestCreatedRevisionName" => "#{name}-00002",
        "latestReadyRevisionName" => "#{name}-00002",
        "observedGeneration" => 2
      }
    }
  end

  def kube_service_full(name: "kubetest", namespace: "kube-ns", domain: "example.com")
    {
      "metadata" => {
        "creationTimestamp" => "2018-11-21T06:16:33Z",
        "name" => name,
        "namespace" => namespace,
        "selfLink" => "/apis/serving.knative.dev/v1alpha1/namespaces/#{namespace}/services/#{name}",
        "annotation" => {
          "description" => "This is a test description"
        }
      },
      "spec" => {
        "generation" => 2,
        "build" => {
          "template" => "go-1.10.3"
        }
      },
      "status" => {
        "domain" => "#{name}.#{namespace}.#{domain}",
        "domainInternal" => "#{name}.#{namespace}.svc.cluster.local",
        "latestCreatedRevisionName" => "#{name}-00002",
        "latestReadyRevisionName" => "#{name}-00002",
        "observedGeneration" => 2
      }
    }
  end

  def kube_terminals(service, pod)
    pod_name = pod['metadata']['name']
    pod_namespace = pod['metadata']['namespace']
    containers = pod['spec']['containers']

    containers.map do |container|
      terminal = {
        selectors: { pod: pod_name, container: container['name'] },
        url:  container_exec_url(service.api_url, pod_namespace, pod_name, container['name']),
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
    ::Gitlab::Kubernetes::RolloutStatus.from_deployments(kube_deployment)
  end

  def empty_deployment_rollout_status
    ::Gitlab::Kubernetes::RolloutStatus.from_deployments
  end
end
