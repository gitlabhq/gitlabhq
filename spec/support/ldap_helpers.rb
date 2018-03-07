module LdapHelpers
  def ldap_adapter(provider = 'ldapmain', ldap = double(:ldap))
    ::Gitlab::Auth::LDAP::Adapter.new(provider, ldap)
  end

  def user_dn(uid)
    "uid=#{uid},ou=users,dc=example,dc=com"
  end

  # Accepts a hash of Gitlab::Auth::LDAP::Config keys and values.
  #
  # Example:
  #   stub_ldap_config(
  #     group_base: 'ou=groups,dc=example,dc=com',
  #     admin_group: 'my-admin-group'
  #   )
  def stub_ldap_config(messages)
    allow_any_instance_of(::Gitlab::Auth::LDAP::Config).to receive_messages(messages)
  end

  # Stub an LDAP person search and provide the return entry. Specify `nil` for
  # `entry` to simulate when an LDAP person is not found
  #
  # Example:
  #  adapter = ::Gitlab::Auth::LDAP::Adapter.new('ldapmain', double(:ldap))
  #  ldap_user_entry = ldap_user_entry('john_doe')
  #
  #  stub_ldap_person_find_by_uid('john_doe', ldap_user_entry, adapter)
  def stub_ldap_person_find_by_uid(uid, entry, provider = 'ldapmain')
    return_value = ::Gitlab::Auth::LDAP::Person.new(entry, provider) if entry.present?

    allow(::Gitlab::Auth::LDAP::Person)
      .to receive(:find_by_uid).with(uid, any_args).and_return(return_value)
  end

  # Create a simple LDAP user entry.
  def ldap_user_entry(uid)
    entry = Net::LDAP::Entry.new
    entry['dn'] = user_dn(uid)
    entry['uid'] = uid

    entry
  end
end
