require_relative 'test_helper'
require 'googleauth'

# Unit tests for the ApplicationDefaultCredentials token provider
class GoogleApplicationDefaultCredentialsTest < MiniTest::Test
  def test_token
    auth = Minitest::Mock.new
    auth.expect(:apply, nil, [{}])
    auth.expect(:access_token, 'valid_token')

    Google::Auth.stub(:get_application_default, auth) do
      assert_equal('valid_token', Kubeclient::GoogleApplicationDefaultCredentials.token)
    end
  end
end
