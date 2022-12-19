require_relative 'test_helper'

# Service entity tests
class TestService < MiniTest::Test
  def test_construct_our_own_service
    our_service = Kubeclient::Resource.new
    our_service.metadata = {}
    our_service.metadata.name = 'guestbook'
    our_service.metadata.namespace = 'staging'
    our_service.metadata.labels = {}
    our_service.metadata.labels.name = 'guestbook'

    our_service.spec = {}
    our_service.spec.ports = [{
      'port' => 3000,
      'targetPort' => 'http-server',
      'protocol' => 'TCP'
    }]

    assert_equal('guestbook', our_service.metadata.labels.name)

    hash = our_service.to_h

    assert_equal(our_service.metadata.labels.name,
                 hash[:metadata][:labels][:name])

    expected_url = 'http://localhost:8080/api/v1/namespaces/staging/services'
    stub_core_api_list
    stub_request(:post, expected_url)
      .to_return(body: open_test_file('created_service.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    created = client.create_service(our_service)

    assert_instance_of(Kubeclient::Resource, created)
    assert_equal(created.metadata.name, our_service.metadata.name)
    assert_equal(created.spec.ports.size, our_service.spec.ports.size)

    # Check that original entity_config is not modified by kind/apiVersion patches:
    assert_nil(our_service.kind)

    assert_requested(:post, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['kind'] == 'Service' &&
        data['apiVersion'] == 'v1' &&
        data['metadata']['name'] == 'guestbook' &&
        data['metadata']['namespace'] == 'staging'
    end
  end

  def test_construct_service_from_symbol_keys
    service = Kubeclient::Resource.new
    service.metadata = {
      labels: { tier: 'frontend' },
      name: 'test-service',
      namespace: 'staging'
    }
    service.spec = {
      ports: [{
        port: 3000,
        targetPort: 'http-server',
        protocol: 'TCP'
      }]
    }

    expected_url = 'http://localhost:8080/api/v1/namespaces/staging/services'
    stub_core_api_list
    stub_request(:post, expected_url)
      .to_return(body: open_test_file('created_service.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    client.create_service(service)

    assert_requested(:post, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['kind'] == 'Service' &&
        data['apiVersion'] == 'v1' &&
        data['metadata']['name'] == 'test-service' &&
        data['metadata']['labels']['tier'] == 'frontend' &&
        data['metadata']['namespace'] == 'staging'
    end
  end

  def test_construct_service_from_string_keys
    service = Kubeclient::Resource.new
    service.metadata = {
      'labels' => { 'tier' => 'frontend' },
      'name' => 'test-service',
      'namespace' => 'staging'
    }
    service.spec = {
      'ports' => [{
        'port' => 3000,
        'targetPort' => 'http-server',
        'protocol' => 'TCP'
      }]
    }

    stub_core_api_list
    expected_url = 'http://localhost:8080/api/v1/namespaces/staging/services'
    stub_request(:post, %r{namespaces/staging/services})
      .to_return(body: open_test_file('created_service.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    client.create_service(service)

    assert_requested(:post, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['kind'] == 'Service' &&
        data['apiVersion'] == 'v1' &&
        data['metadata']['name'] == 'test-service' &&
        data['metadata']['labels']['tier'] == 'frontend' &&
        data['metadata']['namespace'] == 'staging'
    end
  end

  def test_conversion_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/services})
      .to_return(body: open_test_file('service.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    service = client.get_service('redis-slave', 'development')

    assert_instance_of(Kubeclient::Resource, service)
    assert_equal('2015-04-05T13:00:31Z',
                 service.metadata.creationTimestamp)
    assert_equal('bdb80a8f-db93-11e4-b293-f8b156af4ae1', service.metadata.uid)
    assert_equal('redis-slave', service.metadata.name)
    assert_equal('2815', service.metadata.resourceVersion)
    assert_equal('v1', service.apiVersion)
    assert_equal('10.0.0.140', service.spec.clusterIP)
    assert_equal('development', service.metadata.namespace)

    assert_equal('TCP', service.spec.ports[0].protocol)
    assert_equal(6379, service.spec.ports[0].port)
    assert_equal('', service.spec.ports[0].name)
    assert_equal('redis-server', service.spec.ports[0].targetPort)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/development/services/redis-slave',
                     times: 1)
  end

  def test_delete_service
    our_service = Kubeclient::Resource.new
    our_service.name = 'redis-service'
    # TODO, new ports assignment to be added
    our_service.labels = {}
    our_service.labels.component = 'apiserver'
    our_service.labels.provider = 'kubernetes'

    stub_core_api_list
    stub_request(:delete, %r{/namespaces/default/services})
      .to_return(body: open_test_file('service.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    our_service = client.delete_service(our_service.name, 'default')
    assert_kind_of(RecursiveOpenStruct, our_service)

    assert_requested(:delete,
                     'http://localhost:8080/api/v1/namespaces/default/services/redis-service',
                     times: 1)
  end

  def test_get_service_no_ns
    stub_core_api_list
    # when not specifying namespace for entities which
    # are not node or namespace, the request will fail
    stub_request(:get, %r{/services/redis-slave})
      .to_return(status: 404)

    client = Kubeclient::Client.new('http://localhost:8080/api/')

    exception = assert_raises(Kubeclient::HttpError) do
      client.get_service('redis-slave')
    end
    assert_equal(404, exception.error_code)
  end

  def test_get_service
    stub_core_api_list
    stub_request(:get, %r{/namespaces/development/services/redis-slave})
      .to_return(body: open_test_file('service.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    service = client.get_service('redis-slave', 'development')
    assert_equal('redis-slave', service.metadata.name)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/development/services/redis-slave',
                     times: 1)
  end

  def test_update_service
    service = Kubeclient::Resource.new
    name = 'my_service'

    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'

    stub_core_api_list
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:put, expected_url)
      .to_return(body: open_test_file('service_update.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    service = client.update_service(service)
    assert_kind_of(RecursiveOpenStruct, service)

    assert_requested(:put, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['metadata']['name'] == name &&
        data['metadata']['namespace'] == 'development'
    end
  end

  def test_update_service_with_string_keys
    service = Kubeclient::Resource.new
    name = 'my_service'

    service.metadata = {
      'name' => name,
      'namespace' => 'development'
    }

    stub_core_api_list
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:put, expected_url)
      .to_return(body: open_test_file('service_update.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    service = client.update_service(service)
    assert_kind_of(RecursiveOpenStruct, service)

    assert_requested(:put, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['metadata']['name'] == name &&
        data['metadata']['namespace'] == 'development'
    end
  end

  def test_patch_service
    service = Kubeclient::Resource.new
    name = 'my_service'

    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'

    stub_core_api_list
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:patch, expected_url)
      .to_return(body: open_test_file('service_patch.json'), status: 200)

    patch = {
      metadata: {
        annotations: {
          key: 'value'
        }
      }
    }

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    service = client.patch_service(name, patch, 'development')
    assert_kind_of(RecursiveOpenStruct, service)

    assert_requested(:patch, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['metadata']['annotations']['key'] == 'value'
    end
  end

  def test_apply_service
    service = Kubeclient::Resource.new
    name = 'my_service'

    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'
    service.metadata.annotations = {}
    service.metadata.annotations['key'] = 'value'

    stub_core_api_list
    resource_name = "#{name}?fieldManager=myapp&force=true"
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{resource_name}"
    stub_request(:patch, expected_url)
      .to_return(body: open_test_file('service_patch.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    service = client.apply_service(service, field_manager: 'myapp')
    assert_kind_of(RecursiveOpenStruct, service)

    assert_requested(:patch, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      req.headers['Content-Type'] == 'application/apply-patch+yaml' &&
        data['metadata']['annotations']['key'] == 'value'
    end
  end

  def test_json_patch_service
    service = Kubeclient::Resource.new
    name = 'my-service'

    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'

    stub_core_api_list
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:patch, expected_url)
      .to_return(body: open_test_file('service_json_patch.json'), status: 200)

    patch = [
      { 'op' => 'add', 'path' => '/spec/type', 'value' => 'LoadBalancer' }
    ]

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    service = client.json_patch_service(name, patch, 'development')
    assert_kind_of(RecursiveOpenStruct, service)

    assert_requested(:patch, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      req.headers['Content-Type'] == 'application/json-patch+json' &&
        data == patch
    end
  end

  def test_merge_patch_service
    service = Kubeclient::Resource.new
    name = 'my-service'

    service.metadata = {}
    service.metadata.name      = name
    service.metadata.namespace = 'development'

    stub_core_api_list
    expected_url = "http://localhost:8080/api/v1/namespaces/development/services/#{name}"
    stub_request(:patch, expected_url)
      .to_return(body: open_test_file('service_merge_patch.json'), status: 200)

    patch = { spec: { type: 'NodePort' } }

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    service = client.merge_patch_service(name, patch, 'development')
    assert_kind_of(RecursiveOpenStruct, service)

    assert_requested(:patch, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      req.headers['Content-Type'] == 'application/merge-patch+json' &&
        data['spec']['type'] == 'NodePort'
    end
  end
end
