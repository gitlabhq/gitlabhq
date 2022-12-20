require_relative 'test_helper'

# Core api resource list without kind tests
class TestResourceListWithoutKind < MiniTest::Test
  def test_get_from_json_api_v1
    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list_without_kind.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    client.discover

    [
      {
        entity: 'pod',
        type: 'Pod',
        name: 'pods',
        methods: %w[pod pods]
      },
      {
        entity: 'node',
        type: 'Node',
        name: 'nodes',
        methods: %w[node nodes]
      },
      {
        entity: 'service',
        type: 'Service',
        name: 'services',
        methods: %w[service services]
      }
    ].each { |h| assert_entities(client.instance_variable_get(:@entities)[h[:entity]], h) }

    assert_requested(:get,
                     'http://localhost:8080/api/v1',
                     times: 1)
  end

  def test_get_from_json_oapi_v1
    stub_request(:get, %r{/oapi/v1$})
      .to_return(body: open_test_file('core_oapi_resource_list_without_kind.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/oapi/', 'v1')
    client.discover

    [
      {
        entity: 'template',
        type: 'Template',
        name: 'templates',
        methods: %w[template templates]
      },
      {
        entity: 'build',
        type: 'Build',
        name: 'builds',
        methods: %w[build builds]
      },
      {
        entity: 'project',
        type: 'Project',
        name: 'projects',
        methods: %w[project projects]
      }
    ].each { |h| assert_entities(client.instance_variable_get(:@entities)[h[:entity]], h) }

    assert_requested(:get,
                     'http://localhost:8080/oapi/v1',
                     times: 1)
  end

  def assert_entities(entity, h)
    assert_equal(entity.entity_type, h[:type])
    assert_equal(entity.resource_name, h[:name])
    assert_equal(entity.method_names, h[:methods])
  end
end
