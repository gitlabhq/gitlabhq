require_relative 'test_helper'

# PersistentVolumeClaim tests
class TestPersistentVolumeClaim < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/persistentvolumeclaims})
      .to_return(body: open_test_file('persistent_volume_claim.json'), status: 200)
    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    claim = client.get_persistent_volume_claim('myclaim-1', 'default')

    assert_instance_of(Kubeclient::Resource, claim)
    assert_equal('myclaim-1', claim.metadata.name)
    assert_equal('3Gi', claim.spec.resources.requests.storage)
    assert_equal('pv0001', claim.spec.volumeName)

    assert_requested(
      :get,
      'http://localhost:8080/api/v1',
      times: 1
    )
    assert_requested(
      :get,
      'http://localhost:8080/api/v1/namespaces/default/persistentvolumeclaims/myclaim-1',
      times: 1
    )
  end
end
