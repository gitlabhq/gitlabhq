require_relative 'test_helper'

# Pod log tests
class TestPodLog < MiniTest::Test
  def test_get_pod_log
    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log})
      .to_return(body: open_test_file('pod_log.txt'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    retrieved_log = client.get_pod_log('redis-master-pod', 'default')

    assert_equal(open_test_file('pod_log.txt').read, retrieved_log)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/default/pods/redis-master-pod/log',
                     times: 1)
  end

  def test_get_pod_log_container
    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log})
      .to_return(body: open_test_file('pod_log.txt'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    retrieved_log = client.get_pod_log('redis-master-pod', 'default', container: 'ruby')

    assert_equal(open_test_file('pod_log.txt').read, retrieved_log)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/default/pods/redis-master-pod/log?container=ruby',
                     times: 1)
  end

  def test_get_pod_log_since_time
    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log})
      .to_return(body: open_test_file('pod_log.txt'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    retrieved_log = client.get_pod_log('redis-master-pod',
                                       'default',
                                       timestamps: true,
                                       since_time: '2018-04-27T18:30:17.480321984Z')

    assert_equal(open_test_file('pod_log.txt').read, retrieved_log)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/default/pods/redis-master-pod/log?sinceTime=2018-04-27T18:30:17.480321984Z&timestamps=true',
                     times: 1)
  end

  def test_get_pod_log_tail_lines
    selected_lines = open_test_file('pod_log.txt').to_a[-2..1].join

    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log})
      .to_return(body: selected_lines,
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    retrieved_log = client.get_pod_log('redis-master-pod',
                                       'default',
                                       tail_lines: 2)

    assert_equal(selected_lines, retrieved_log)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/default/pods/redis-master-pod/log?tailLines=2',
                     times: 1)
  end

  def test_get_pod_limit_bytes
    selected_bytes = open_test_file('pod_log.txt').read(10)

    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log})
      .to_return(body: selected_bytes,
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    retrieved_log = client.get_pod_log('redis-master-pod',
                                       'default',
                                       limit_bytes: 10)

    assert_equal(selected_bytes, retrieved_log)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/default/pods/redis-master-pod/log?limitBytes=10',
                     times: 1)
  end

  def test_watch_pod_log
    file = open_test_file('pod_log.txt')
    expected_lines = file.read.split("\n")

    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log\?.*follow})
      .to_return(body: file, status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    stream = client.watch_pod_log('redis-master-pod', 'default')
    stream.to_enum.with_index do |notice, index|
      assert_instance_of(String, notice)
      assert_equal(expected_lines[index], notice)
    end
  end

  def test_watch_pod_log_with_block
    file = open_test_file('pod_log.txt')
    first = file.readlines.first.chomp

    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log\?.*follow})
      .to_return(body: file, status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    client.watch_pod_log('redis-master-pod', 'default') do |line|
      assert_equal first, line
      break
    end
  end

  def test_watch_pod_log_follow_redirect
    expected_lines = open_test_file('pod_log.txt').read.split("\n")
    redirect = 'http://localhost:1234/api/namespaces/default/pods/redis-master-pod/log'

    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log\?.*follow})
      .to_return(status: 302, headers: { location: redirect })

    stub_request(:get, redirect)
      .to_return(body: open_test_file('pod_log.txt'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    stream = client.watch_pod_log('redis-master-pod', 'default')
    stream.to_enum.with_index do |notice, index|
      assert_instance_of(String, notice)
      assert_equal(expected_lines[index], notice)
    end
  end

  def test_watch_pod_log_max_redirect
    redirect = 'http://localhost:1234/api/namespaces/default/pods/redis-master-pod/log'

    stub_request(:get, %r{/namespaces/default/pods/[a-z0-9-]+/log\?.*follow})
      .to_return(status: 302, headers: { location: redirect })

    stub_request(:get, redirect)
      .to_return(body: open_test_file('pod_log.txt'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1', http_max_redirects: 0)
    assert_raises(Kubeclient::HttpError) do
      client.watch_pod_log('redis-master-pod', 'default').each do
      end
    end
  end
end
