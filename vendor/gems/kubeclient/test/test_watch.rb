require_relative 'test_helper'

# Watch entity tests
class TestWatch < MiniTest::Test
  def test_watch_pod_success
    stub_core_api_list

    expected = [
      { 'type' => 'ADDED', 'resourceVersion' => '1389' },
      { 'type' => 'MODIFIED', 'resourceVersion' => '1390' },
      { 'type' => 'DELETED', 'resourceVersion' => '1398' }
    ]

    stub_request(:get, %r{/watch/pods})
      .to_return(body: open_test_file('watch_stream.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    client.watch_pods.to_enum.with_index do |notice, index|
      assert_instance_of(Kubeclient::Resource, notice)
      assert_equal(expected[index]['type'], notice.type)
      assert_equal('Pod', notice.object.kind)
      assert_equal('php', notice.object.metadata.name)
      assert_equal(expected[index]['resourceVersion'],
                   notice.object.metadata.resourceVersion)
    end
  end

  def test_watch_pod_block
    stub_core_api_list
    stub_request(:get, %r{/watch/pods})
      .to_return(body: open_test_file('watch_stream.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    yielded = []
    client.watch_pods { |notice| yielded << notice.type }

    assert_equal %w[ADDED MODIFIED DELETED], yielded
  end

  def test_watch_pod_raw
    stub_core_api_list

    stub_request(:get, %r{/watch/pods}).to_return(
      body: open_test_file('watch_stream.json'),
      status: 200
    )

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    got = nil
    client.watch_pods(as: :raw).each { |notice| got = notice }
    assert_match(/\A{"type":"DELETED"/, got)
  end

  def test_watch_pod_failure
    stub_core_api_list
    stub_request(:get, %r{/watch/pods}).to_return(status: 404)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    assert_raises(Kubeclient::HttpError) do
      client.watch_pods.each do
      end
    end
  end

  def test_watch_pod_follow_redirect
    stub_core_api_list

    redirect = 'http://localhost:1234/api/v1/watch/pods'
    stub_request(:get, %r{/watch/pods})
      .to_return(status: 302, headers: { location: redirect })

    stub_request(:get, redirect).to_return(
      body: open_test_file('watch_stream.json'),
      status: 200
    )

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')

    got = nil
    client.watch_pods.each { |notice| got = notice }
    assert_equal('DELETED', got.type)
  end

  def test_watch_pod_max_redirect
    stub_core_api_list

    redirect = 'http://localhost:1234/api/v1/watcher/pods'
    stub_request(:get, %r{/watch/pods})
      .to_return(status: 302, headers: { location: redirect })

    stub_request(:get, redirect).to_return(
      body: open_test_file('watch_stream.json'),
      status: 200
    )

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1', http_max_redirects: 0)

    assert_raises(Kubeclient::HttpError) do
      client.watch_pods.each do
      end
    end
  end

  # Ensure that WatchStream respects a format that's not JSON
  def test_watch_stream_text
    url = 'http://www.example.com/foobar'
    expected_lines = open_test_file('pod_log.txt').read.split("\n")

    stub_request(:get, url)
      .to_return(body: open_test_file('pod_log.txt'),
                 status: 200)

    stream = Kubeclient::Common::WatchStream.new(URI.parse(url), {}, formatter: ->(v) { v })
    stream.to_enum.with_index do |line, index|
      assert_instance_of(String, line)
      assert_equal(expected_lines[index], line)
    end
  end

  def test_watch_with_resource_version
    api_host = 'http://localhost:8080/api'
    version = '1995'
    stub_core_api_list
    stub_request(:get, %r{.*\/watch/events})
      .to_return(body: open_test_file('watch_stream.json'),
                 status: 200)

    client = Kubeclient::Client.new(api_host, 'v1')
    results = client.watch_events(version).to_enum

    assert_equal(3, results.count)
    assert_requested(:get,
                     "#{api_host}/v1/watch/events?resourceVersion=#{version}",
                     times: 1)
  end

  def test_watch_with_label_selector
    api_host = 'http://localhost:8080/api'
    selector = 'name=redis-master'

    stub_core_api_list
    stub_request(:get, %r{.*\/watch/events})
      .to_return(body: open_test_file('watch_stream.json'),
                 status: 200)

    client = Kubeclient::Client.new(api_host, 'v1')
    results = client.watch_events(label_selector: selector).to_enum

    assert_equal(3, results.count)
    assert_requested(:get,
                     "#{api_host}/v1/watch/events?labelSelector=#{selector}",
                     times: 1)
  end

  def test_watch_with_field_selector
    api_host = 'http://localhost:8080/api'
    selector = 'involvedObject.kind=Pod'

    stub_core_api_list
    stub_request(:get, %r{.*\/watch/events})
      .to_return(body: open_test_file('watch_stream.json'),
                 status: 200)

    client = Kubeclient::Client.new(api_host, 'v1')
    results = client.watch_events(field_selector: selector).to_enum

    assert_equal(3, results.count)
    assert_requested(:get,
                     "#{api_host}/v1/watch/events?fieldSelector=#{selector}",
                     times: 1)
  end

  def test_watch_with_finish_and_ebadf
    api_host = 'http://localhost:8080/api'

    stub_core_api_list
    stub_request(:get, %r{.*\/watch/events})
      .to_return(body: open_test_file('watch_stream.json'), status: 200)

    client = Kubeclient::Client.new(api_host, 'v1')
    watcher = client.watch_events

    # explodes when StandardError is not caught
    watcher.each do
      watcher.finish
      raise StandardError
    end

    assert_requested(:get, "#{api_host}/v1/watch/events", times: 1)
  end
end
