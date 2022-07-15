# frozen_string_literal: true

RSpec.shared_context 'Ldap::OmniauthCallbacksController' do
  include LoginHelpers
  include LdapHelpers

  let(:uid) { 'my-uid' }
  let(:provider) { 'ldapmain' }
  let(:valid_login?) { true }
  let(:user) { create(:omniauth_user, extern_uid: uid, provider: provider) }
  let(:ldap_setting_defaults) { { enabled: true, servers: ldap_server_config } }
  let(:ldap_settings) { ldap_setting_defaults }
  let(:ldap_server_config) do
    { main: ldap_config_defaults(:main) }
  end

  let(:multiple_ldap_servers_license_available) { true }

  def ldap_config_defaults(key, hash = {})
    {
      provider_name: "ldap#{key}",
      attributes: {},
      encryption: 'plain'
    }.merge(hash)
  end

  before do
    stub_licensed_features(multiple_ldap_servers: multiple_ldap_servers_license_available)
    stub_ldap_setting(ldap_settings)
    described_class.define_providers!
    Rails.application.reload_routes!

    @original_env_config_omniauth_auth = mock_auth_hash(provider.to_s, uid, user.email)
    stub_omniauth_provider(provider, context: request)

    allow(Gitlab::Auth::Ldap::Access).to receive(:allowed?).and_return(valid_login?)
  end

  after do
    Rails.application.env_config['omniauth.auth'] = @original_env_config_omniauth_auth
  end

  after(:all) do
    Rails.application.reload_routes!
  end
end
