require_relative 'test_helper'

# Pod entity tests
class TestPod < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('pod.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    pod = client.get_pod('redis-master-pod', 'default')

    assert_instance_of(Kubeclient::Resource, pod)
    assert_equal('redis-master3', pod.metadata.name)
    assert_equal('dockerfile/redis', pod.spec.containers[0]['image'])

    assert_requested(
      :get,
      'http://localhost:8080/api/v1',
      times: 1
    )
    assert_requested(
      :get,
      'http://localhost:8080/api/v1/namespaces/default/pods/redis-master-pod',
      times: 1
    )
  end

  def test_get_chunks
    stub_core_api_list
    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('pods_1.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    pods = client.get_pods(limit: 2)

    assert_equal(2, pods.count)
    assert_equal('eyJ2IjoibWV0YS5rOHMua', pods.continue)

    continue = pods.continue

    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('pods_2.json'), status: 200)

    pods = client.get_pods(limit: 2, continue: continue)
    assert_equal(2, pods.count)
    assert_nil(pods.continue)

    assert_requested(
      :get,
      'http://localhost:8080/api/v1',
      times: 1
    )
    assert_requested(
      :get,
      'http://localhost:8080/api/v1/pods?limit=2',
      times: 1
    )
    assert_requested(
      :get,
      "http://localhost:8080/api/v1/pods?continue=#{continue}&limit=2",
      times: 1
    )
  end

  def test_get_chunks_410_gone
    stub_core_api_list
    stub_request(:get, %r{/pods})
      .to_return(body: open_test_file('pods_410.json'), status: 410)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    err = assert_raises Kubeclient::HttpError do
      client.get_pods(limit: 2, continue: 'eyJ2IjoibWV0YS5')
    end

    assert_equal(err.message,
                 "The provided from parameter is too old to display a consistent list result. \
You must start a new list without the from.")
  end
end
