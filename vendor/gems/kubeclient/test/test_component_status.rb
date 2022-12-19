require_relative 'test_helper'

# ComponentStatus tests
class TestComponentStatus < MiniTest::Test
  def test_get_from_json_v3
    stub_core_api_list
    stub_request(:get, %r{/componentstatuses})
      .to_return(body: open_test_file('component_status.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    component_status = client.get_component_status('etcd-0', 'default')

    assert_instance_of(Kubeclient::Resource, component_status)
    assert_equal('etcd-0', component_status.metadata.name)
    assert_equal('Healthy', component_status.conditions[0].type)
    assert_equal('True', component_status.conditions[0].status)

    assert_requested(
      :get,
      'http://localhost:8080/api/v1',
      times: 1
    )
    assert_requested(
      :get,
      'http://localhost:8080/api/v1/namespaces/default/componentstatuses/etcd-0',
      times: 1
    )
  end
end
