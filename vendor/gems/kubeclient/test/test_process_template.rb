require_relative 'test_helper'

# Process Template tests
class TestProcessTemplate < MiniTest::Test
  def test_process_template
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    template = {}
    template[:metadata] = {}
    template[:metadata][:name] = 'my-template'
    template[:metadata][:namespace] = 'default'
    template[:kind] = 'Template'
    template[:apiVersion] = 'v1'
    service = {}
    service[:metadata] = {}
    service[:metadata][:name] = '${NAME_PREFIX}my-service'
    service[:kind] = 'Service'
    service[:apiVersion] = 'v1'
    template[:objects] = [service]
    param = { name: 'NAME_PREFIX', value: 'test/' }
    template[:parameters] = [param]

    req_body = '{"metadata":{"name":"my-template","namespace":"default"},' \
      '"kind":"Template","apiVersion":"v1","objects":[{"metadata":' \
      '{"name":"${NAME_PREFIX}my-service"},"kind":"Service","apiVersion":"v1"}],' \
      '"parameters":[{"name":"NAME_PREFIX","value":"test/"}]}'

    expected_url = 'http://localhost:8080/api/v1/namespaces/default/processedtemplates'
    stub_request(:post, expected_url)
      .with(body: req_body, headers: { 'Content-Type' => 'application/json' })
      .to_return(body: open_test_file('processed_template.json'), status: 200)

    processed_template = client.process_template(template)

    assert_equal('test/my-service', processed_template['objects'].first['metadata']['name'])

    assert_requested(:post, expected_url, times: 1) do |req|
      data = JSON.parse(req.body)
      data['kind'] == 'Template' &&
        data['apiVersion'] == 'v1' &&
        data['metadata']['name'] == 'my-template' &&
        data['metadata']['namespace'] == 'default'
    end
  end

  # Ensure _template and _templates methods hit `/templates` rather than
  # `/processedtemplates` URL.
  def test_templates_methods
    stub_request(:get, %r{/apis/template\.openshift\.io/v1$}).to_return(
      body: open_test_file('template.openshift.io_api_resource_list.json'),
      status: 200
    )
    client = Kubeclient::Client.new('http://localhost:8080/apis/template.openshift.io', 'v1')

    expected_url = 'http://localhost:8080/apis/template.openshift.io/v1/namespaces/default/templates'
    stub_request(:get, expected_url)
      .to_return(body: open_test_file('template_list.json'), status: 200)
    client.get_templates(namespace: 'default')
    assert_requested(:get, expected_url, times: 1)

    expected_url = 'http://localhost:8080/apis/template.openshift.io/v1/namespaces/default/templates/my-template'
    stub_request(:get, expected_url)
      .to_return(body: open_test_file('template.json'), status: 200)
    client.get_template('my-template', 'default')
    assert_requested(:get, expected_url, times: 1)
  end

  def test_no_processedtemplates_methods
    stub_request(:get, %r{/apis/template\.openshift\.io/v1$}).to_return(
      body: open_test_file('template.openshift.io_api_resource_list.json'),
      status: 200
    )
    client = Kubeclient::Client.new('http://localhost:8080/apis/template.openshift.io', 'v1')
    client.discover

    refute_respond_to(client, :get_processedtemplates)
    refute_respond_to(client, :get_processedtemplate)
    refute_respond_to(client, :get_processed_templates)
    refute_respond_to(client, :get_processed_template)
  end
end
