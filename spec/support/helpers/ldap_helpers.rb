# frozen_string_literal: true

module LdapHelpers
  def ldap_adapter(provider = 'ldapmain', ldap = double(:ldap))
    ::Gitlab::Auth::Ldap::Adapter.new(provider, ldap)
  end

  def user_dn(uid)
    "uid=#{uid},ou=users,dc=example,dc=com"
  end

  # Accepts a hash of Gitlab::Auth::Ldap::Config keys and values.
  #
  # Example:
  #   stub_ldap_config(
  #     group_base: 'ou=groups,dc=example,dc=com',
  #     admin_group: 'my-admin-group'
  #   )
  def stub_ldap_config(messages)
    allow_any_instance_of(::Gitlab::Auth::Ldap::Config).to receive_messages(to_settings(messages))
  end

  def stub_ldap_setting(messages)
    allow(Gitlab.config.ldap).to receive_messages(to_settings(messages))
  end

  # Stub an LDAP person search and provide the return entry. Specify `nil` for
  # `entry` to simulate when an LDAP person is not found
  #
  # Example:
  #  adapter = ::Gitlab::Auth::Ldap::Adapter.new('ldapmain', double(:ldap))
  #  ldap_user_entry = ldap_user_entry('john_doe')
  #
  #  stub_ldap_person_find_by_uid('john_doe', ldap_user_entry, adapter)
  def stub_ldap_person_find_by_uid(uid, entry, provider = 'ldapmain')
    return_value = ::Gitlab::Auth::Ldap::Person.new(entry, provider) if entry.present?

    allow(::Gitlab::Auth::Ldap::Person)
      .to receive(:find_by_uid).with(uid, any_args).and_return(return_value)
  end

  def stub_ldap_person_find_by_dn(entry, provider = 'ldapmain')
    person = ::Gitlab::Auth::Ldap::Person.new(entry, provider) if entry.present?

    allow(::Gitlab::Auth::Ldap::Person)
      .to receive(:find_by_dn)
      .and_return(person)
  end

  def stub_ldap_person_find_by_email(email, entry, provider = 'ldapmain')
    person = ::Gitlab::Auth::Ldap::Person.new(entry, provider) if entry.present?

    allow(::Gitlab::Auth::Ldap::Person)
      .to receive(:find_by_email)
      .with(email, anything)
      .and_return(person)
  end

  # Create a simple LDAP user entry.
  def ldap_user_entry(uid)
    entry = Net::LDAP::Entry.new
    entry['dn'] = user_dn(uid)
    entry['uid'] = uid

    entry
  end

  def raise_ldap_connection_error
    allow_any_instance_of(Gitlab::Auth::Ldap::Adapter)
      .to receive(:ldap_search).and_raise(Gitlab::Auth::Ldap::LdapConnectionError)
  end

  def stub_ldap_access(user, provider, provider_label)
    ldap_server_config =
      {
        'label' => provider_label,
        'provider_name' => provider,
        'attributes' => {},
        'encryption' => 'plain',
        'uid' => 'uid',
        'base' => 'dc=example,dc=com'
      }
    uid = 'my-uid'
    allow(::Gitlab::Auth::Ldap::Config).to receive_messages(enabled: true, servers: [ldap_server_config])
    allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [provider.to_sym])

    Ldap::OmniauthCallbacksController.define_providers!
    Rails.application.reload_routes!

    mock_auth_hash(provider, uid, user.email)
    allow(Gitlab::Auth::Ldap::Access).to receive(:allowed?).with(user).and_return(true)

    allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
      allow(instance).to receive(:"user_#{provider}_omniauth_callback_path")
              .and_return("/users/auth/#{provider}/callback")
    end
  end
end

LdapHelpers.include_mod_with('LdapHelpers')
