require_relative 'test_helper'
require 'open3'

# Unit tests for the GCPCommandCredentials token provider
class GCPCommandCredentialsTest < MiniTest::Test
  def test_token
    opts = { 'cmd-args' => 'config config-helper --format=json',
             'cmd-path' => '/path/to/gcloud',
             'expiry-key' => '{.credential.token_expiry}',
             'token-key' => '{.credential.access_token}' }

    creds = JSON.dump(
      'credential' => {
        'access_token' => '9A3A941836F2458175BE18AA1971EBBF47949B07',
        'token_expiry' => '2019-04-12T15:02:51Z'
      }
    )

    st = Minitest::Mock.new
    st.expect(:success?, true)

    Open3.stub(:capture3, [creds, nil, st]) do
      assert_equal('9A3A941836F2458175BE18AA1971EBBF47949B07',
                   Kubeclient::GCPCommandCredentials.token(opts))
    end
  end
end
