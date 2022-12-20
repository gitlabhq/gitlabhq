require_relative 'test_helper'
require 'openid_connect'

class OIDCAuthProviderTest < MiniTest::Test
  def setup
    @client_id = 'client_id'
    @client_secret = 'client_secret'
    @idp_issuer_url = 'idp_issuer_url'
    @refresh_token = 'refresh_token'
    @id_token = 'id_token'
    @new_id_token = 'new_id_token'
  end

  def test_expired_token
    OpenIDConnect::Discovery::Provider::Config.stub(:discover!, discovery_mock) do
      OpenIDConnect::ResponseObject::IdToken.stub(:decode, id_token_mock(Time.now.to_i - 7200)) do
        OpenIDConnect::Client.stub(:new, openid_client_mock) do
          retrieved_id_token = Kubeclient::OIDCAuthProvider.token(
            'client-id' => @client_id,
            'client-secret' => @client_secret,
            'id-token' => @id_token,
            'idp-issuer-url' => @idp_issuer_url,
            'refresh-token' => @refresh_token
          )
          assert_equal(@new_id_token, retrieved_id_token)
        end
      end
    end
  end

  def test_valid_token
    OpenIDConnect::Discovery::Provider::Config.stub(:discover!, discovery_mock) do
      OpenIDConnect::ResponseObject::IdToken.stub(:decode, id_token_mock(Time.now.to_i + 7200)) do
        retrieved_id_token = Kubeclient::OIDCAuthProvider.token(
          'client-id' => @client_id,
          'client-secret' => @client_secret,
          'id-token' => @id_token,
          'idp-issuer-url' => @idp_issuer_url,
          'refresh-token' => @refresh_token
        )
        assert_equal(@id_token, retrieved_id_token)
      end
    end
  end

  def test_missing_id_token
    OpenIDConnect::Discovery::Provider::Config.stub(:discover!, discovery_mock) do
      OpenIDConnect::Client.stub(:new, openid_client_mock) do
        retrieved_id_token = Kubeclient::OIDCAuthProvider.token(
          'client-id' => @client_id,
          'client-secret' => @client_secret,
          'idp-issuer-url' => @idp_issuer_url,
          'refresh-token' => @refresh_token
        )
        assert_equal(@new_id_token, retrieved_id_token)
      end
    end
  end

  def test_token_with_unknown_kid
    OpenIDConnect::Discovery::Provider::Config.stub(:discover!, discovery_mock) do
      OpenIDConnect::ResponseObject::IdToken.stub(
        :decode, ->(_token, _jwks) { raise JSON::JWK::Set::KidNotFound }
      ) do
        OpenIDConnect::Client.stub(:new, openid_client_mock) do
          retrieved_id_token = Kubeclient::OIDCAuthProvider.token(
            'client-id' => @client_id,
            'client-secret' => @client_secret,
            'id-token' => @id_token,
            'idp-issuer-url' => @idp_issuer_url,
            'refresh-token' => @refresh_token
          )
          assert_equal(@new_id_token, retrieved_id_token)
        end
      end
    end
  end

  private

  def openid_client_mock
    access_token = Minitest::Mock.new
    access_token.expect(@id_token, @new_id_token)

    openid_client = Minitest::Mock.new
    openid_client.expect(:refresh_token=, nil, [@refresh_token])
    openid_client.expect(:access_token!, access_token)
  end

  def id_token_mock(expiry)
    id_token_mock = Minitest::Mock.new
    id_token_mock.expect(:exp, expiry)
  end

  def discovery_mock
    discovery = Minitest::Mock.new
    discovery.expect(:jwks, 'jwks')
    discovery.expect(:authorization_endpoint, 'authz_endpoint')
    discovery.expect(:token_endpoint, 'token_endpoint')
    discovery.expect(:userinfo_endpoint, 'userinfo_endpoint')
    discovery
  end
end
