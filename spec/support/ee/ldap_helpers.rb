module EE
  module LdapHelpers
    def proxy(adapter, provider = 'ldapmain')
      EE::Gitlab::LDAP::Sync::Proxy.new(provider, adapter)
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
      if entry.present?
        return_value = EE::Gitlab::LDAP::Group.new(entry, adapter)
      end

      allow(EE::Gitlab::LDAP::Group)
        .to receive(:find_by_cn)
          .with(cn, kind_of(::Gitlab::LDAP::Adapter)).and_return(return_value)
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
end
