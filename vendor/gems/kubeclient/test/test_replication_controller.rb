require_relative 'test_helper'

# Replication Controller entity tests
class TestReplicationController < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/replicationcontrollers})
      .to_return(body: open_test_file('replication_controller.json'),
                 status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    rc = client.get_replication_controller('frontendController', 'default')

    assert_instance_of(Kubeclient::Resource, rc)
    assert_equal('guestbook-controller', rc.metadata.name)
    assert_equal('c71aa4c0-a240-11e4-a265-3c970e4a436a', rc.metadata.uid)
    assert_equal('default', rc.metadata.namespace)
    assert_equal(3, rc.spec.replicas)
    assert_equal('guestbook', rc.spec.selector.name)

    assert_requested(:get,
                     'http://localhost:8080/api/v1/namespaces/default/replicationcontrollers/frontendController',
                     times: 1)
  end

  def test_delete_replicaset_cascade
    stub_core_api_list
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    opts = Kubeclient::Resource.new(
      apiVersion: 'meta/v1',
      gracePeriodSeconds: 0,
      kind: 'DeleteOptions',
      propagationPolicy: 'Foreground'
    )

    stub_request(:delete,
                 'http://localhost:8080/api/v1/namespaces/default/replicationcontrollers/frontendController')
      .with(body: opts.to_hash.to_json)
      .to_return(status: 200, body: open_test_file('replication_controller.json'), headers: {})
    rc = client.delete_replication_controller('frontendController', 'default', delete_options: opts)
    assert_kind_of(RecursiveOpenStruct, rc)

    assert_requested(:delete,
                     'http://localhost:8080/api/v1/namespaces/default/replicationcontrollers/frontendController',
                     times: 1)
  end
end
