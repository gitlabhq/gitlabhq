require_relative 'test_helper'

# Namespace entity tests
class TestNamespace < MiniTest::Test
  def test_get_namespace_v1
    stub_core_api_list
    stub_request(:get, %r{/namespaces})
      .to_return(body: open_test_file('namespace.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    namespace = client.get_namespace('staging')

    assert_instance_of(Kubeclient::Resource, namespace)
    assert_equal('e388bc10-c021-11e4-a514-3c970e4a436a', namespace.metadata.uid)
    assert_equal('staging', namespace.metadata.name)
    assert_equal('1168', namespace.metadata.resourceVersion)
    assert_equal('v1', namespace.apiVersion)

    assert_requested(
      :get,
      'http://localhost:8080/api/v1/namespaces/staging',
      times: 1
    )
  end

  def test_delete_namespace_v1
    our_namespace = Kubeclient::Resource.new
    our_namespace.metadata = {}
    our_namespace.metadata.name = 'staging'

    stub_core_api_list
    stub_request(:delete, %r{/namespaces})
      .to_return(body: open_test_file('namespace.json'), status: 200)
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    our_namespace = client.delete_namespace(our_namespace.metadata.name)
    assert_kind_of(RecursiveOpenStruct, our_namespace)

    assert_requested(
      :delete,
      'http://localhost:8080/api/v1/namespaces/staging',
      times: 1
    )
  end

  def test_create_namespace
    stub_core_api_list
    stub_request(:post, %r{/namespaces})
      .to_return(body: open_test_file('created_namespace.json'), status: 201)

    namespace = Kubeclient::Resource.new
    namespace.metadata = {}
    namespace.metadata.name = 'development'

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    created_namespace = client.create_namespace(namespace)
    assert_instance_of(Kubeclient::Resource, created_namespace)
    assert_equal(namespace.metadata.name, created_namespace.metadata.name)
  end
end
