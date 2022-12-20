require_relative 'test_helper'

# Namespace entity tests
class TestSecret < MiniTest::Test
  def test_get_secret_v1
    stub_core_api_list
    stub_request(:get, %r{/secrets})
      .to_return(body: open_test_file('created_secret.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    secret = client.get_secret('test-secret', 'dev')

    assert_instance_of(Kubeclient::Resource, secret)
    assert_equal('4e38a198-2bcb-11e5-a483-0e840567604d', secret.metadata.uid)
    assert_equal('test-secret', secret.metadata.name)
    assert_equal('v1', secret.apiVersion)
    assert_equal('Y2F0J3MgYXJlIGF3ZXNvbWUK', secret.data['super-secret'])

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/dev/secrets/test-secret',
                     times: 1)
  end

  def test_delete_secret_v1
    stub_core_api_list
    stub_request(:delete, %r{/secrets})
      .to_return(status: 200, body: open_test_file('created_secret.json'))

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    secret = client.delete_secret('test-secret', 'dev')
    assert_kind_of(RecursiveOpenStruct, secret)

    assert_requested(:delete,
                     'http://localhost:8080/api/v1/namespaces/dev/secrets/test-secret',
                     times: 1)
  end

  def test_create_secret_v1
    stub_core_api_list
    stub_request(:post, %r{/secrets})
      .to_return(body: open_test_file('created_secret.json'),
                 status: 201)

    secret = Kubeclient::Resource.new
    secret.metadata = {}
    secret.metadata.name = 'test-secret'
    secret.metadata.namespace = 'dev'
    secret.data = {}
    secret.data['super-secret'] = 'Y2F0J3MgYXJlIGF3ZXNvbWUK'

    client = Kubeclient::Client.new('http://localhost:8080/api/')
    created_secret = client.create_secret(secret)
    assert_instance_of(Kubeclient::Resource, created_secret)
    assert_equal(secret.metadata.name, created_secret.metadata.name)
    assert_equal(secret.metadata.namespace, created_secret.metadata.namespace)
    assert_equal(
      secret.data['super-secret'],
      created_secret.data['super-secret']
    )
  end
end
