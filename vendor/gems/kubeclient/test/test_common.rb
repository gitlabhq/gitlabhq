
require_relative 'test_helper'

# Unit tests for the common module
class CommonTest < MiniTest::Test
  class ClientStub
    include Kubeclient::ClientMixin
  end

  def client
    @client ||= ClientStub.new
  end

  def test_underscore_entity
    %w[
      Pod pod
      Service service
      ReplicationController replication_controller
      Node node
      Event event
      Endpoint endpoint
      Namespace namespace
      Secret secret
      ResourceQuota resource_quota
      LimitRange limit_range
      PersistentVolume persistent_volume
      PersistentVolumeClaim persistent_volume_claim
      ComponentStatus component_status
      ServiceAccount service_account
      Project project
      Route route
      ClusterRoleBinding cluster_role_binding
      Build build
      BuildConfig build_config
      Image image
      ImageStream image_stream
      dogstatsd dogstatsd
      lowerCamelUPPERCase lower_camel_uppercase
      HTTPAPISpecBinding httpapispec_binding
      APIGroup apigroup
      APIGroupList apigroup_list
      APIResourceList apiresource_list
      APIService apiservice
      APIServiceList apiservice_list
      APIVersions apiversions
      OAuthAccessToken oauth_access_token
      OAuthAccessTokenList oauth_access_token_list
      OAuthAuthorizeToken oauth_authorize_token
      OAuthAuthorizeTokenList oauth_authorize_token_list
      OAuthClient oauth_client
      OAuthClientAuthorization oauth_client_authorization
      OAuthClientAuthorizationList oauth_client_authorization_list
      OAuthClientList oauth_client_list
    ].each_slice(2) do |kind, expected_underscore|
      underscore = Kubeclient::ClientMixin.underscore_entity(kind)
      assert_equal(underscore, expected_underscore)
    end
  end

  def test_format_datetime_with_string
    value = '2018-04-27T18:30:17.480321984Z'
    formatted = client.send(:format_datetime, value)
    assert_equal(formatted, value)
  end

  def test_format_datetime_with_datetime
    value = DateTime.new(2018, 4, 30, 19, 20, 33)
    formatted = client.send(:format_datetime, value)
    assert_equal(formatted, '2018-04-30T19:20:33.000000000+00:00')
  end

  def test_format_datetime_with_time
    value = Time.new(2018, 4, 30, 19, 20, 33, 0)
    formatted = client.send(:format_datetime, value)
    assert_equal(formatted, '2018-04-30T19:20:33.000000000+00:00')
  end

  def test_parse_definition_with_unconventional_names
    %w[
      PluralPolicy pluralpolicies plural_policy plural_policies
      LatinDatum latindata latin_datum latin_data
      Noseparator noseparators noseparator noseparators
      lowercase lowercases lowercase lowercases
      TestWithDash test-with-dashes test_with_dash test_with_dashes
      TestUnderscore test_underscores test_underscore test_underscores
      TestMismatch other-odd-name testmismatch otheroddname
      MixedDashMinus mixed-dash_minuses mixed_dash_minus mixed_dash_minuses
      SameUptoWordboundary sameup-toword-boundarys sameuptowordboundary sameuptowordboundarys
    ].each_slice(4) do |kind, plural, expected_single, expected_plural|
      method_names = Kubeclient::ClientMixin.parse_definition(kind, plural).method_names
      assert_equal(method_names[0], expected_single)
      assert_equal(method_names[1], expected_plural)
    end
  end
end
