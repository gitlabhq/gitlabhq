require 'spec_helper'

shared_context 'Ldap::OmniauthCallbacksController' do
  include LoginHelpers
  include LdapHelpers

  let(:uid) { 'my-uid' }
  let(:provider) { 'ldapmain' }
  let(:valid_login?) { true }
  let(:user) { create(:omniauth_user, extern_uid: uid, provider: provider) }
  let(:ldap_server_config) do
    { main: ldap_config_defaults(:main) }
  end

  def ldap_config_defaults(key, hash = {})
    {
      provider_name: "ldap#{key}",
      attributes: {},
      encryption: 'plain'
    }.merge(hash)
  end

  before do
    stub_ldap_setting(enabled: true, servers: ldap_server_config)
    described_class.define_providers!
    Rails.application.reload_routes!

    mock_auth_hash(provider.to_s, uid, user.email)
    stub_omniauth_provider(provider, context: request)

    allow(Gitlab::Auth::LDAP::Access).to receive(:allowed?).and_return(valid_login?)
  end
end
