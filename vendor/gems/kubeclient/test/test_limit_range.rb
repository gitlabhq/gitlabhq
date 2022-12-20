require_relative 'test_helper'

# LimitRange tests
class TestLimitRange < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/limitranges})
      .to_return(body: open_test_file('limit_range.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    limit_range = client.get_limit_range('limits', 'quota-example')

    assert_instance_of(Kubeclient::Resource, limit_range)
    assert_equal('limits', limit_range.metadata.name)
    assert_equal('Container', limit_range.spec.limits[0].type)
    assert_equal('100m', limit_range.spec.limits[0].default.cpu)
    assert_equal('512Mi', limit_range.spec.limits[0].default.memory)

    assert_requested(
      :get,
      'http://localhost:8080/api/v1/namespaces/quota-example/limitranges/limits',
      times: 1
    )
  end
end
