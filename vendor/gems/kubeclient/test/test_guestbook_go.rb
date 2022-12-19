require_relative 'test_helper'
require 'vcr'

# creation of google's example of guest book
class CreateGuestbookGo < MiniTest::Test
  def test_create_guestbook_entities
    VCR.configure do |c|
      c.cassette_library_dir = 'test/cassettes'
      c.hook_into(:webmock)
    end

    # WebMock.allow_net_connect!
    VCR.use_cassette('kubernetes_guestbook') do # , record: :new_episodes) do
      client = Kubeclient::Client.new('http://10.35.0.23:8080/api/', 'v1')

      testing_ns = Kubeclient::Resource.new
      testing_ns.metadata = {}
      testing_ns.metadata.name = 'kubeclient-ns'

      # delete in case they existed before so creation can be tested
      delete_namespace(client, testing_ns.metadata.name)
      delete_services(
        client, testing_ns.metadata.name,
        ['guestbook', 'redis-master', 'redis-slave']
      )
      delete_replication_controllers(
        client, testing_ns.metadata.name,
        ['guestbook', 'redis-master', 'redis-slave']
      )

      client.create_namespace(testing_ns)
      services = create_services(client, testing_ns.metadata.name)
      replicators = create_replication_controllers(client, testing_ns.metadata.name)

      get_namespaces(client)
      get_services(client, testing_ns.metadata.name)
      get_replication_controllers(client, testing_ns.metadata.name)

      delete_services(client, testing_ns.metadata.name, services)
      delete_replication_controllers(client, testing_ns.metadata.name, replicators)

      client.delete_namespace(testing_ns.metadata.name)
    end
  ensure
    VCR.turn_off!
  end

  def delete_namespace(client, namespace_name)
    client.delete_namespace(namespace_name)
  rescue Kubeclient::ResourceNotFoundError => exception
    assert_equal(404, exception.error_code)
  end

  def get_namespaces(client)
    namespaces = client.get_namespaces
    assert(true, namespaces.size > 2)
  end

  def get_services(client, ns)
    retrieved_services = client.get_services(namespace: ns)
    assert_equal(3, retrieved_services.size)
  end

  def get_replication_controllers(client, ns)
    retrieved_replicators = client.get_replication_controllers(namespace: ns)
    assert_equal(3, retrieved_replicators.size)
  end

  def create_services(client, ns)
    guestbook_service = client.create_service(guestbook_service(ns))
    redis_service = client.create_service(redis_service(ns))
    redis_slave_service = client.create_service(redis_slave_service(ns))
    [guestbook_service, redis_service, redis_slave_service]
  end

  def create_replication_controllers(client, namespace)
    rc = client.create_replication_controller(guestbook_rc(namespace))
    rc2 = client.create_replication_controller(redis_master_rc(namespace))
    rc3 = client.create_replication_controller(redis_slave_rc(namespace))
    [rc, rc2, rc3]
  end

  def delete_services(client, namespace, services)
    # if the entity is not found, no need to fail the test
    services.each do |service|
      begin
        if service.instance_of?(Kubeclient::Resource)
          client.delete_service(service.metadata.name, namespace)
        else
          # it's just a string - service name
          client.delete_service(service, namespace)
        end
      rescue Kubeclient::ResourceNotFoundError => exception
        assert_equal(404, exception.error_code)
      end
    end
  end

  def delete_replication_controllers(client, namespace, replication_controllers)
    # if the entity is not found, no need to fail the test
    replication_controllers.each do |rc|
      begin
        if rc.instance_of?(Kubeclient::Resource)
          client.delete_replication_controller(rc.metadata.name, namespace)
        else
          # it's just a string - rc name
          client.delete_replication_controller(rc, namespace)
        end
      rescue Kubeclient::ResourceNotFoundError => exception
        assert_equal(404, exception.error_code)
      end
    end
  end

  private

  def construct_base_rc(namespace)
    rc = Kubeclient::Resource.new
    rc.metadata = {}
    rc.metadata.namespace = namespace
    rc.metadata.labels = {}
    rc.spec = {}
    rc.spec.selector = {}
    rc.spec.template = {}
    rc.spec.template.metadata = {}
    rc.spec.template.spec = {}
    rc.spec.template.metadata.labels = {}
    rc
  end

  def redis_master_rc(namespace)
    rc = construct_base_rc(namespace)
    rc.metadata.name = 'redis-master'
    rc.metadata.labels.app = 'redis'
    rc.metadata.labels.role = 'master'
    rc.spec.replicas = 1
    rc.spec.selector.app = 'redis'
    rc.spec.selector.role = 'master'
    rc.spec.template.metadata.labels.app = 'redis'
    rc.spec.template.metadata.labels.role = 'master'
    rc.spec.template.spec.containers = [{
      'name' => 'redis-master',
      'image' => 'redis',
      'ports' => [{
        'name' => 'redis-server',
        'containerPort' => 6379
      }]
    }]
    rc
  end

  def redis_slave_rc(namespace)
    rc = construct_base_rc(namespace)
    rc.metadata.name = 'redis-slave'
    rc.metadata.labels.app = 'redis'
    rc.metadata.labels.role = 'slave'
    rc.spec.replicas = 2
    rc.spec.selector.app = 'redis'
    rc.spec.selector.role = 'slave'
    rc.spec.template.metadata.labels.app = 'redis'
    rc.spec.template.metadata.labels.role = 'slave'
    rc.spec.template.spec.containers = [{
      'name'          => 'redis-slave',
      'image'         => 'kubernetes/redis-slave:v2',
      'ports'         => [{
        'name'          => 'redis-server',
        'containerPort' => 6379
      }]
    }]
    rc
  end

  def guestbook_rc(namespace)
    rc = construct_base_rc(namespace)
    rc.metadata.name = 'guestbook'
    rc.metadata.labels.app = 'guestbook'
    rc.metadata.labels.role = 'slave'
    rc.spec.replicas = 3
    rc.spec.selector.app = 'guestbook'
    rc.spec.template.metadata.labels.app = 'guestbook'
    rc.spec.template.spec.containers = [
      {
        'name'     => 'guestbook',
        'image'    => 'kubernetes/guestbook:v2',
        'ports'    => [
          {
            'name'          => 'http-server',
            'containerPort' => 3000
          }
        ]
      }
    ]
    rc
  end

  def base_service(namespace)
    our_service = Kubeclient::Resource.new
    our_service.metadata = {}
    our_service.metadata.namespace = namespace
    our_service.metadata.labels = {}
    our_service.spec = {}
    our_service.spec.selector = {}
    our_service
  end

  def redis_slave_service(namespace)
    our_service = base_service(namespace)
    our_service.metadata.name = 'redis-slave'
    our_service.metadata.labels.app = 'redis'
    our_service.metadata.labels.role = 'slave'
    our_service.spec.ports = [{ 'port' => 6379, 'targetPort' => 'redis-server' }]
    our_service.spec.selector.app = 'redis'
    our_service.spec.selector.role = 'slave'
    our_service
  end

  def redis_service(namespace)
    our_service = base_service(namespace)
    our_service.metadata.name = 'redis-master'
    our_service.metadata.labels.app = 'redis'
    our_service.metadata.labels.role = 'master'
    our_service.spec.ports = [{ 'port' => 6379, 'targetPort' => 'redis-server' }]
    our_service.spec.selector.app = 'redis'
    our_service.spec.selector.role = 'master'
    our_service
  end

  def guestbook_service(namespace)
    our_service = base_service(namespace)
    our_service.metadata.name = 'guestbook'
    our_service.metadata.labels.name = 'guestbook'
    our_service.spec.ports = [{ 'port' => 3000, 'targetPort' => 'http-server' }]
    our_service.spec.selector.app = 'guestbook'
    our_service.type = 'LoadBalancer'
    our_service
  end
end
