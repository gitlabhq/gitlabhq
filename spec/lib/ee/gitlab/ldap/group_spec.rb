require 'spec_helper'

describe EE::Gitlab::LDAP::Group, lib: true do
  describe '#member_dns' do
    def ldif
      Net::LDAP::Entry.from_single_ldif_string(
        <<-EOS.strip_heredoc
          dn: cn=ldap_group1,ou=groups,dc=example,dc=com
          cn: ldap_group1
          description: LDAP Group 1
          member: uid=user1,ou=users,dc=example,dc=com
          member: uid=user2,ou=users,dc=example,dc=com
          member: uid=user3,ou=users,dc=example,dc=com
          objectclass: top
          objectclass: groupOfNames
        EOS
      )
    end

    def adapter
      @adapter ||= Gitlab::LDAP::Adapter.new('ldapmain')
    end

    let(:group) { described_class.new(ldif, adapter) }
    let(:recursive_dns) do
      %w(
        uid=user3,ou=users,dc=example,dc=com
        uid=user4,ou=users,dc=example,dc=com
        uid=user5,ou=users,dc=example,dc=com
      )
    end

    it 'concatenates recursive and regular results and returns uniq' do
      allow(group).to receive(:active_directory?).and_return(true)
      allow(adapter).to receive(:dns_for_filter).and_return(recursive_dns)

      expect(group.member_dns)
        .to match_array(
          %w(
            uid=user1,ou=users,dc=example,dc=com
            uid=user2,ou=users,dc=example,dc=com
            uid=user3,ou=users,dc=example,dc=com
            uid=user4,ou=users,dc=example,dc=com
            uid=user5,ou=users,dc=example,dc=com
          )
        )
    end

  end
end
