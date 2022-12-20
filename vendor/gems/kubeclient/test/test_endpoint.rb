require_relative 'test_helper'

# kind: 'Endpoints' entity tests.
# This is one of the unusual `kind`s that are already plural (https://github.com/kubernetes/kubernetes/issues/8115).
# We force singular in method names like 'create_endpoint',
# but `kind` should remain plural as in kubernetes.
class TestEndpoint < MiniTest::Test
  def test_create_endpoint
    stub_core_api_list
    testing_ep = Kubeclient::Resource.new
    testing_ep.metadata = {}
    testing_ep.metadata.name = 'myendpoint'
    testing_ep.metadata.namespace = 'default'
    testing_ep.subsets = [
      {
        'addresses' => [{ 'ip' => '172.17.0.25' }],
        'ports' => [{ 'name' => 'https', 'port' => 6443, 'protocol' => 'TCP' }]
      }
    ]

    req_body = '{"metadata":{"name":"myendpoint","namespace":"default"},' \
      '"subsets":[{"addresses":[{"ip":"172.17.0.25"}],"ports":[{"name":"https",' \
      '"port":6443,"protocol":"TCP"}]}],"kind":"Endpoints","apiVersion":"v1"}'

    stub_request(:post, 'http://localhost:8080/api/v1/namespaces/default/endpoints')
      .with(body: req_body)
      .to_return(body: open_test_file('created_endpoint.json'), status: 201)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    created_ep = client.create_endpoint(testing_ep)
    assert_equal('Endpoints', created_ep.kind)
    assert_equal('v1', created_ep.apiVersion)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1', as: :parsed_symbolized)
    created_ep = client.create_endpoint(testing_ep)
    assert_equal('Endpoints', created_ep[:kind])
    assert_equal('v1', created_ep[:apiVersion])
  end

  def test_get_endpoints
    stub_core_api_list
    stub_request(:get, %r{/endpoints})
      .to_return(body: open_test_file('endpoint_list.json'), status: 200)
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    collection = client.get_endpoints(as: :parsed_symbolized)
    assert_equal('EndpointsList', collection[:kind])
    assert_equal('v1', collection[:apiVersion])

    # Stripping of 'List' in collection.kind RecursiveOpenStruct mode only is historic.
    collection = client.get_endpoints
    assert_equal('Endpoints', collection.kind)
  end
end
