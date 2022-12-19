require_relative 'test_helper'

class KubeclientRealClusterTest < MiniTest::Test
  # Tests here actually connect to a cluster!
  # For simplicity, these tests use same config/*.kubeconfig files as test_config.rb,
  # so are intended to run from config/update_certs_k0s.rb script.
  def setup
    if ENV['KUBECLIENT_TEST_REAL_CLUSTER'] == 'true'
      WebMock.enable_net_connect!
    else
      skip('Requires real cluster, see test/config/update_certs_k0s.rb.')
    end
  end

  def teardown
    WebMock.disable_net_connect! # Don't allow any connections in other tests.
  end

  # Partially isolated tests that check Client behavior with given `verify_ssl` value:

  # localhost and 127.0.0.1 are among names on the certificate
  HOSTNAME_COVERED_BY_CERT = 'https://127.0.0.1:6443'.freeze
  # 127.0.0.2 also means localhost but is not included in the certificate.
  HOSTNAME_NOT_ON_CERT = 'https://127.0.0.2:6443'.freeze

  def test_real_cluster_verify_peer
    config = Kubeclient::Config.read(config_file('external.kubeconfig'))
    context = config.context
    client1 = Kubeclient::Client.new(
      HOSTNAME_COVERED_BY_CERT, 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_PEER),
      auth_options: context.auth_options
    )
    check_cert_accepted(client1)
    client2 = Kubeclient::Client.new(
      HOSTNAME_NOT_ON_CERT, 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_PEER),
      auth_options: context.auth_options
    )
    check_cert_rejected(client2)
  end

  def test_real_cluster_verify_none
    config = Kubeclient::Config.read(config_file('external.kubeconfig'))
    context = config.context
    client1 = Kubeclient::Client.new(
      HOSTNAME_COVERED_BY_CERT, 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_NONE),
      auth_options: context.auth_options
    )
    check_cert_accepted(client1)
    client2 = Kubeclient::Client.new(
      HOSTNAME_NOT_ON_CERT, 'v1',
      ssl_options: context.ssl_options.merge(verify_ssl: OpenSSL::SSL::VERIFY_NONE),
      auth_options: context.auth_options
    )
    check_cert_accepted(client2)
  end

  # Integration tests that check combined Config -> Client behavior wrt. `verify_ssl`.
  # Quite redundant, but this was an embarrasing vulnerability so want to confirm...

  def test_real_cluster_concatenated_ca
    config = Kubeclient::Config.read(config_file('concatenated-ca.kubeconfig'))
    context = config.context
    client1 = Kubeclient::Client.new(
      HOSTNAME_COVERED_BY_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_accepted(client1)
    client2 = Kubeclient::Client.new(
      HOSTNAME_NOT_ON_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_rejected(client2)
  end

  def test_real_cluster_verify_ssl_with_ca
    config = Kubeclient::Config.read(config_file('external.kubeconfig'))
    context = config.context
    client1 = Kubeclient::Client.new(
      HOSTNAME_COVERED_BY_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_accepted(client1)
    client2 = Kubeclient::Client.new(
      HOSTNAME_NOT_ON_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_rejected(client2)
  end

  def test_real_cluster_verify_ssl_without_ca
    config = Kubeclient::Config.read(config_file('external-without-ca.kubeconfig'))
    context = config.context
    # Hostname matches cert but the local cluster uses self-signed certs from custom CA,
    # and this config omits CA data, so verification can't succeed.
    client1 = Kubeclient::Client.new(
      HOSTNAME_COVERED_BY_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_rejected(client1)
    client2 = Kubeclient::Client.new(
      HOSTNAME_NOT_ON_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_rejected(client2)
  end

  def test_real_cluster_insecure_without_ca
    config = Kubeclient::Config.read(config_file('insecure.kubeconfig'))
    context = config.context
    # Hostname matches cert but the local cluster uses self-signed certs from custom CA,
    # and this config omits CA data, so verification would fail;
    # however, this config specifies `insecure-skip-tls-verify: true` so any cert goes.
    client1 = Kubeclient::Client.new(
      HOSTNAME_COVERED_BY_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_accepted(client1)
    client2 = Kubeclient::Client.new(
      HOSTNAME_NOT_ON_CERT, 'v1',
      ssl_options: context.ssl_options, auth_options: context.auth_options
    )
    check_cert_accepted(client2)
  end

  private

  # Test cert checking on discovery, CRUD, and watch code paths.
  def check_cert_accepted(client)
    client.discover
    client.get_nodes
    exercise_watcher_with_timeout(client.watch_nodes)
  end

  def check_cert_rejected(client)
    # TODO: all OpenSSL exceptions should be wrapped with Kubeclient error.
    assert_raises(Kubeclient::HttpError, OpenSSL::SSL::SSLError) do
      client.discover
    end
    # Since discovery fails, methods like .get_nodes, .watch_nodes would all fail
    # on method_missing -> discover.  Call lower-level methods to test actual connection.
    assert_raises(Kubeclient::HttpError, OpenSSL::SSL::SSLError) do
      client.get_entities('Node', 'nodes', {})
    end
    assert_raises(Kubeclient::HttpError, OpenSSL::SSL::SSLError) do
      exercise_watcher_with_timeout(client.watch_entities('nodes'))
    end
  end

  def exercise_watcher_with_timeout(watcher)
    thread = Thread.new do
      sleep(1)
      watcher.finish
    end
    watcher.each do |_notice|
      break
    end
    thread.join
  end
end
