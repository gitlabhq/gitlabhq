require_relative 'test_helper'

# ResourceQuota tests
class TestResourceQuota < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/resourcequotas})
      .to_return(body: open_test_file('resource_quota.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    quota = client.get_resource_quota('quota', 'quota-example')

    assert_instance_of(Kubeclient::Resource, quota)
    assert_equal('quota', quota.metadata.name)
    assert_equal('20', quota.spec.hard.cpu)
    assert_equal('10', quota.spec.hard.secrets)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/quota-example/resourcequotas/quota',
                     times: 1)
  end
end
