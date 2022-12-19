require_relative 'test_helper'

# PersistentVolume tests
class TestPersistentVolume < MiniTest::Test
  def test_get_from_json_v1
    stub_core_api_list
    stub_request(:get, %r{/persistentvolumes})
      .to_return(body: open_test_file('persistent_volume.json'), status: 200)

    client = Kubeclient::Client.new('http://localhost:8080/api/', 'v1')
    volume = client.get_persistent_volume('pv0001')

    assert_instance_of(Kubeclient::Resource, volume)
    assert_equal('pv0001', volume.metadata.name)
    assert_equal('10Gi', volume.spec.capacity.storage)
    assert_equal('/tmp/data01', volume.spec.hostPath.path)

    assert_requested(
      :get,
      'http://localhost:8080/api/v1',
      times: 1
    )
    assert_requested(
      :get,
      'http://localhost:8080/api/v1/persistentvolumes/pv0001',
      times: 1
    )
  end
end
