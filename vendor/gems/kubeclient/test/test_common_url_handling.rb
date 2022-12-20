require_relative 'test_helper'

# URLHandling tests
class TestCommonUrlHandling < MiniTest::Test
  def test_no_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/api/v1', rest_client.url.to_s)
  end

  def test_with_api_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/api', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/api/v1', rest_client.url.to_s)
  end

  def test_with_api_path_in_uri_other_version
    client = Kubeclient::Client.new('http://localhost:8080/api', 'v2')
    rest_client = client.rest_client
    assert_equal('v2', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/api/v2', rest_client.url.to_s)
  end

  def test_with_api_group_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/apis/this_is_the_group', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('this_is_the_group/', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/apis/this_is_the_group/v1', rest_client.url.to_s)
  end

  def test_with_api_group_path_in_uri_other_version
    client = Kubeclient::Client.new('http://localhost:8080/apis/this_is_the_group', 'v2')
    rest_client = client.rest_client
    assert_equal('v2', client.instance_variable_get(:@api_version))
    assert_equal('this_is_the_group/', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/apis/this_is_the_group/v2', rest_client.url.to_s)
  end

  def test_with_api_path_in_uri_trailing_slash
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/api/v1', rest_client.url.to_s)
  end

  def test_with_api_path_in_api
    client = Kubeclient::Client.new('http://localhost:8080/api/but/I/want/a/hidden/k8s/api', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/api/but/I/want/a/hidden/k8s/api/v1', rest_client.url.to_s)
  end

  def test_with_api_group_path_in_api
    client = Kubeclient::Client.new(
      'http://localhost:8080/api/but/I/want/a/hidden/k8s/apis/this_is_the_group',
      'v1'
    )
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('this_is_the_group/', client.instance_variable_get(:@api_group))
    assert_equal(
      'http://localhost:8080/api/but/I/want/a/hidden/k8s/apis/this_is_the_group/v1',
      rest_client.url.to_s
    )
  end

  def test_rancher_with_api_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/k8s/clusters/c-somerancherID/api', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/k8s/clusters/c-somerancherID/api/v1', rest_client.url.to_s)
  end

  def test_rancher_no_api_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/k8s/clusters/c-somerancherID', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/k8s/clusters/c-somerancherID/api/v1', rest_client.url.to_s)
  end

  def test_rancher_no_api_path_in_uri_trailing_slash
    client = Kubeclient::Client.new('http://localhost:8080/k8s/clusters/c-somerancherID/', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/k8s/clusters/c-somerancherID/api/v1', rest_client.url.to_s)
  end

  def test_rancher_with_api_path_in_uri_trailing_slash
    client = Kubeclient::Client.new('http://localhost:8080/k8s/clusters/c-somerancherID/api/', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/k8s/clusters/c-somerancherID/api/v1', rest_client.url.to_s)
  end

  def test_rancher_with_api_group_in_uri_trailing_slash
    client = Kubeclient::Client.new(
      'http://localhost:8080/k8s/clusters/c-somerancherID/apis/this_is_the_group',
      'v1'
    )
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('this_is_the_group/', client.instance_variable_get(:@api_group))
    assert_equal(
      'http://localhost:8080/k8s/clusters/c-somerancherID/apis/this_is_the_group/v1',
      rest_client.url.to_s
    )
  end

  def test_with_openshift_api_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/oapi', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/oapi/v1', rest_client.url.to_s)
  end

  def test_arbitrary_path_with_openshift_api_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/foobarbaz/oapi', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/foobarbaz/oapi/v1', rest_client.url.to_s)
  end

  def test_with_openshift_api_path_in_uri_trailing_slash
    client = Kubeclient::Client.new('http://localhost:8080/oapi/', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/oapi/v1', rest_client.url.to_s)
  end

  def test_with_arbitrary_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/foobarbaz', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/foobarbaz/api/v1', rest_client.url.to_s)
  end

  def test_with_arbitrary_and_api_path_in_uri
    client = Kubeclient::Client.new('http://localhost:8080/foobarbaz/api', 'v1')
    rest_client = client.rest_client
    assert_equal('v1', client.instance_variable_get(:@api_version))
    assert_equal('', client.instance_variable_get(:@api_group))
    assert_equal('http://localhost:8080/foobarbaz/api/v1', rest_client.url.to_s)
  end
end
