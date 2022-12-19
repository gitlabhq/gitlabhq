require_relative 'test_helper'
require 'open3'

# Unit tests for the ExecCredentials provider
class ExecCredentialsTest < MiniTest::Test
  def test_exec_opts_missing
    expected_msg =
      'exec options are required'
    exception = assert_raises(ArgumentError) do
      Kubeclient::ExecCredentials.run(nil)
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_exec_command_missing
    expected_msg =
      'exec command is required'
    exception = assert_raises(KeyError) do
      Kubeclient::ExecCredentials.run({})
    end
    assert_equal(expected_msg, exception.message)
  end

  def test_exec_command_failure
    err = 'Error'
    expected_msg =
      "exec command failed: #{err}"

    st = Minitest::Mock.new
    st.expect(:success?, false)

    opts = { 'command' => 'dummy' }

    Open3.stub(:capture3, [nil, err, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end

  def test_run_with_token_credentials
    opts = { 'command' => 'dummy' }

    credentials = {
      'token' => '0123456789ABCDEF0123456789ABCDEF'
    }

    creds = JSON.dump(
      'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
      'status' => credentials
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    Open3.stub(:capture3, [creds, nil, st]) do
      assert_equal(credentials, Kubeclient::ExecCredentials.run(opts))
    end
  end

  def test_run_with_client_credentials
    opts = { 'command' => 'dummy' }

    credentials = {
      'clientCertificateData' => '0123456789ABCDEF0123456789ABCDEF',
      'clientKeyData' => '0123456789ABCDEF0123456789ABCDEF'
    }

    creds = JSON.dump(
      'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
      'status' => credentials
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    Open3.stub(:capture3, [creds, nil, st]) do
      assert_equal(credentials, Kubeclient::ExecCredentials.run(opts))
    end
  end

  def test_run_with_missing_client_certificate_data
    opts = { 'command' => 'dummy' }

    credentials = {
      'clientKeyData' => '0123456789ABCDEF0123456789ABCDEF'
    }

    creds = JSON.dump(
      'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
      'status' => credentials
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    expected_msg = 'exec plugin didn\'t return client certificate data'

    Open3.stub(:capture3, [creds, nil, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end

  def test_run_with_missing_client_key_data
    opts = { 'command' => 'dummy' }

    credentials = {
      'clientCertificateData' => '0123456789ABCDEF0123456789ABCDEF'
    }

    creds = JSON.dump(
      'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
      'status' => credentials
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    expected_msg = 'exec plugin didn\'t return client key data'

    Open3.stub(:capture3, [creds, nil, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end

  def test_run_with_client_data_and_token
    opts = { 'command' => 'dummy' }

    credentials = {
      'clientCertificateData' => '0123456789ABCDEF0123456789ABCDEF',
      'clientKeyData' => '0123456789ABCDEF0123456789ABCDEF',
      'token' => '0123456789ABCDEF0123456789ABCDEF'
    }

    creds = JSON.dump(
      'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
      'status' => credentials
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    expected_msg = 'exec plugin returned both token and client data'

    Open3.stub(:capture3, [creds, nil, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end

  def test_status_missing
    opts = { 'command' => 'dummy' }

    creds = JSON.dump('apiVersion' => 'client.authentication.k8s.io/v1alpha1')

    st = Minitest::Mock.new
    st.expect(:success?, true)

    expected_msg = 'exec plugin didn\'t return a status field'

    Open3.stub(:capture3, [creds, nil, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end

  def test_credentials_missing
    opts = { 'command' => 'dummy' }

    creds = JSON.dump(
      'apiVersion' => 'client.authentication.k8s.io/v1alpha1',
      'status' => {}
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    expected_msg = 'exec plugin didn\'t return a token or client data'

    Open3.stub(:capture3, [creds, nil, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end

  def test_api_version_mismatch
    api_version = 'client.authentication.k8s.io/v1alpha1'
    expected_version = 'client.authentication.k8s.io/v1beta1'

    opts = {
      'command' => 'dummy',
      'apiVersion' => expected_version
    }

    creds = JSON.dump(
      'apiVersion' => api_version
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    expected_msg = "exec plugin is configured to use API version #{expected_version}," \
      " plugin returned version #{api_version}"

    Open3.stub(:capture3, [creds, nil, st]) do
      exception = assert_raises(RuntimeError) do
        Kubeclient::ExecCredentials.run(opts)
      end
      assert_equal(expected_msg, exception.message)
    end
  end
end
