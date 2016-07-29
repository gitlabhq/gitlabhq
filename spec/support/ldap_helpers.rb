module LdapHelpers
  def adapter(provider = 'ldapmain')
    ::Gitlab::LDAP::Adapter.new(provider, double(:ldap))
  end

  def proxy(adapter, provider = 'ldapmain')
    EE::Gitlab::LDAP::Sync::Proxy.new(provider, adapter)
  end

  def user_dn(uid)
    "uid=#{uid},ou=users,dc=example,dc=com"
  end

  # Accepts a hash of Gitlab::LDAP::Config keys and values.
  #
  # Example:
  #   stub_ldap_config(
  #     group_base: 'ou=groups,dc=example,dc=com',
  #     admin_group: 'my-admin-group'
  #   )
  def stub_ldap_config(messages)
    messages.each do |config, value|
      allow_any_instance_of(::Gitlab::LDAP::Config)
        .to receive(config.to_sym).and_return(value)
    end
  end

  # Stub an LDAP person search and provide the return entry. Specify `nil` for
  # `entry` to simulate when an LDAP person is not found
  #
  # Example:
  #  adapter = ::Gitlab::LDAP::Adapter.new('ldapmain', double(:ldap))
  #  ldap_user_entry = ldap_user_entry('john_doe')
  #
  #  stub_ldap_person_find_by_uid('john_doe', ldap_user_entry, adapter)
  def stub_ldap_person_find_by_uid(uid, entry, provider = 'ldapmain')
    return_value = if entry.present?
                     ::Gitlab::LDAP::Person.new(entry, provider)
                   else
                     nil
                   end

    allow(::Gitlab::LDAP::Person)
      .to receive(:find_by_uid).with(uid, any_args).and_return(return_value)
  end

  # Stub an LDAP group search and provide the return entry. Specify `nil` for
  # `entry` to simulate when an LDAP group is not found
  #
  # Example:
  #  adapter = ::Gitlab::LDAP::Adapter.new('ldapmain', double(:ldap))
  #  ldap_group1 = ldap_group_entry('uid=user,ou=users,dc=example,dc=com')
  #
  #  stub_ldap_group_find_by_cn('ldap_group1', ldap_group1, adapter)
  def stub_ldap_group_find_by_cn(cn, entry, adapter = nil)
    return_value = if entry.present?
                     EE::Gitlab::LDAP::Group.new(entry, adapter)
                   else
                     nil
                   end

    allow(EE::Gitlab::LDAP::Group)
      .to receive(:find_by_cn)
        .with(cn, kind_of(::Gitlab::LDAP::Adapter)).and_return(return_value)
  end

  # Create a simple LDAP user entry.
  def ldap_user_entry(uid)
    Net::LDAP::Entry.from_single_ldif_string("dn: #{user_dn(uid)}")
  end

  # Create an LDAP group entry with any number of members. By default, creates
  # a groupOfNames style entry. Change the style by specifying the object class
  # and member attribute name. The last example below shows how to specify a
  # posixGroup (Apple Open Directory) entry. `members` can be nil to create
  # an empty group.
  #
  # Example:
  #   ldap_group_entry('uid=user,ou=users,dc=example,dc=com')
  #
  #   ldap_group_entry(
  #     'uid=user1,ou=users,dc=example,dc=com',
  #     'uid=user2,ou=users,dc=example,dc=com'
  #   )
  #
  #   ldap_group_entry(
  #     [ 'user1', 'user2' ],
  #     cn: 'my_group'
  #     objectclass: 'posixGroup',
  #     member_attr: 'memberUid'
  #   )
  def ldap_group_entry(
    members,
    cn: 'ldap_group1',
    objectclass: 'groupOfNames',
    member_attr: 'uniqueMember'
  )
    entry = Net::LDAP::Entry.from_single_ldif_string(<<-EOS.strip_heredoc)
      dn: cn=#{cn},ou=groups,dc=example,dc=com
      cn: #{cn}
      description: LDAP Group #{cn}
      objectclass: top
      objectclass: #{objectclass}
    EOS

    members = [members].flatten
    entry[member_attr] = members if members.any?
    entry
  end
end
