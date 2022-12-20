require_relative 'test_helper'

# ServiceAccount tests
class TestServiceAccount < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/serviceaccounts})
      .to_return(body: open_test_file('service_account.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    account = client.get_service_account('default')

    assert_instance_of(Kubeclient::Resource, account)
    assert_equal('default', account.metadata.name)
    assert_equal('default-token-6s23q', account.secrets[0].name)
    assert_equal('default-dockercfg-62tf3', account.secrets[1].name)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/serviceaccounts/default',
                     times: 1)
    assert_requested(:get,
                     'http://localhost:8080/api/v1',
                     times: 1)
  end
end
