require 'spec_helper'

describe Gitlab::LDAP::Access do
  let(:access) { Gitlab::LDAP::Access.new user }
  let(:user) { create(:user, :ldap) }

  describe :allowed? do
    subject { access.allowed? }

    context 'when the user cannot be found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: nil) }

      it { should be_false }
    end

    context 'when the user is found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: :ldap_user) }

      context 'and the user is diabled via active directory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: true) }

        it { should be_false }
      end

      context 'and has no disabled flag in active diretory' do
        before { Gitlab::LDAP::Person.stub(disabled_via_active_directory?: false) }

        it { should be_true }
      end

      context 'withoud ActiveDirectory enabled' do
        before do
          Gitlab::LDAP::Config.stub(enabled?: true)
          Gitlab::LDAP::Config.any_instance.stub(active_directory: false)
        end

        it { should be_true }
      end
    end
  end

  describe :update_permissions do
    subject { access.update_permissions }

    it "syncs ssh keys if enabled by configuration" do
      access.stub sync_ssh_keys?: 'sshpublickey'
      expect(access).to receive(:update_ssh_keys).once

      subject
    end

    it "does update group permissions with a group base configured" do
      access.stub group_base: 'my-group-base'
      expect(access).to receive(:update_ldap_group_links)

      subject
    end

    it "does not update group permissions without a group base configured" do
      access.stub group_base: ''
      expect(access).not_to receive(:update_ldap_group_links)

      subject
    end

    it "does update admin group permissions if admin group is configured" do
      access.stub admin_group: 'my-admin-group'
      access.stub :update_ldap_group_links
      expect(access).to receive(:update_admin_status)

      subject
    end
  end

  describe :update_ssh_keys do
    let(:ssh_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj' }
    let(:ssh_key_attribute_name) { 'sshpublickey' }
    let(:entry) {
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: #{ssh_key}") }

    before do
      Gitlab::LDAP::Config.any_instance.stub(sync_ssh_keys: ssh_key_attribute_name)
      access.stub sync_ssh_keys?: true
    end

    it "should add a SSH key if it is in LDAP but not in gitlab" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: #{ssh_key}")
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

      expect{ access.update_ssh_keys }.to change(user.keys, :count).from(0).to(1)
    end

    it "should add a SSH key and give it a proper name" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: #{ssh_key}")
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

      access.update_ssh_keys
      expect(user.keys.last.title).to match(/LDAP/)
      expect(user.keys.last.title).to match(/#{access.ldap_config.sync_ssh_keys}/)
    end

    it "should not add a SSH key if it is invalid" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: I am not a valid key")
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

      expect{ access.update_ssh_keys }.to_not change(user.keys, :count)
    end

    context 'user has at least one LDAPKey' do
      before { user.keys.ldap.create key: ssh_key, title: 'to be removed' }

      it "should remove a SSH key if it is no longer in LDAP" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}:\n")
        Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

        expect{ access.update_ssh_keys }.to change(user.keys, :count).from(1).to(0)
      end

      it "should remove a SSH key if the ldap attribute was removed" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
        Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

        expect{ access.update_ssh_keys }.to change(user.keys, :count).from(1).to(0)
      end
    end
  end

  describe :update_user_email do
    let(:entry) { Net::LDAP::Entry.new }

    before do
      access.stub ldap_user: Gitlab::LDAP::Person.new(entry, user.provider)
    end

    it "should not update email if email attribute is not set" do
      expect{ access.update_email }.to_not change(user, :unconfirmed_email)
    end

    it "should not update the email if the user has the same email in GitLab and in LDAP" do
      entry['mail'] = [user.email]
      expect{ access.update_email }.to_not change(user, :unconfirmed_email)
    end

    it "should not update the email if the user has the same email GitLab and in LDAP, but with upper case in LDAP" do
      entry['mail'] = [user.email.upcase]
      expect{ access.update_email }.to_not change(user, :unconfirmed_email)
    end

    it "should update the email if the user email is different" do
      entry['mail'] = ["new_email@example.com"]
      expect{ access.update_email }.to change(user, :unconfirmed_email)
    end
  end


  describe :update_admin_status do
    before do
      access.stub(admin_group: "GLAdmins")
      ldap_user_entry = Net::LDAP::Entry.new
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(ldap_user_entry, user.provider) }
      Gitlab::LDAP::Person.any_instance.stub(:uid) { 'admin2' }
    end

    it "should give admin privileges to an User" do
      admin_group = Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=#{access.admin_group},ou=groups,dc=bar,dc=com
cn: #{access.admin_group}
description: GitLab admins
gidnumber: 42
memberuid: admin1
memberuid: admin2
memberuid: admin3
objectclass: top
objectclass: posixGroup
})
      Gitlab::LDAP::Adapter.any_instance.stub(:group) { Gitlab::LDAP::Group.new(admin_group) }

      expect{ access.update_admin_status }.to change(user, :admin?).to(true)
    end

    it "should remove admin privileges from an User" do
      user.update_attribute(:admin, true)
      admin_group = Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=#{access.admin_group},ou=groups,dc=bar,dc=com
cn: #{access.admin_group}
description: GitLab admins
gidnumber: 42
memberuid: admin1
memberuid: admin3
objectclass: top
objectclass: posixGroup
})
      Gitlab::LDAP::Adapter.any_instance.stub(:group) { Gitlab::LDAP::Group.new(admin_group) }
      expect{ access.update_admin_status }.to change(user, :admin?).to(false)
    end
  end


  describe :update_ldap_group_links do
    let(:cns_with_access) { %w(ldap-group1 ldap-group2) }
    let(:gitlab_group_1) { create :group }
    let(:gitlab_group_2) { create :group }

    before do
      access.stub(cns_with_access: cns_with_access)
    end

    context "non existing access for group-1, allowed via ldap-group1 as MASTER" do
      before do
        gitlab_group_1.ldap_group_links.create({
          cn: 'ldap-group1', group_access: Gitlab::Access::MASTER })
      end

      it "gives the user master access for group 1" do
        access.update_ldap_group_links
        expect( gitlab_group_1.has_master?(user) ).to be_true
      end
    end

    context "existing access as guest for group-1, allowed via ldap-group1 as DEVELOPER" do
      before do
        gitlab_group_1.group_members.guests.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create cn: 'ldap-group1', group_access: Gitlab::Access::MASTER
      end

      it "upgrades the users access to master for group 1" do
        expect { access.update_ldap_group_links }.to \
          change{ gitlab_group_1.has_master?(user) }.from(false).to(true)
      end
    end

    context "existing access as MASTER for group-1, allowed via ldap-group1 as DEVELOPER" do
      before do
        gitlab_group_1.group_members.masters.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create cn: 'ldap-group1', group_access: Gitlab::Access::DEVELOPER
      end

      it "keeps the users master access for group 1" do
        expect { access.update_ldap_group_links }.not_to \
          change{ gitlab_group_1.has_master?(user) }
      end
    end

    context "existing access as master for group-1, not allowed" do
      before do
        gitlab_group_1.group_members.masters.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create cn: 'ldap-group1', group_access: Gitlab::Access::MASTER
        access.stub(cns_with_access: ['ldap-group2'])
      end

      it "removes user from gitlab_group_1" do
        expect { access.update_ldap_group_links }.to \
          change{ gitlab_group_1.members.where(user_id: user).any? }.from(true).to(false)
      end
    end
  end

  describe 'ldap_groups' do
    let(:ldap_group_1) do
      Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=#{Gitlab.config.ldap['admin_group']},ou=groups,dc=bar,dc=com
cn: #{Gitlab.config.ldap['admin_group']}
description: GitLab group 1
gidnumber: 42
memberuid: user1
memberuid: user2
objectclass: top
objectclass: posixGroup
})
    end

    it "returns an interator of LDAP Groups" do
      ::LdapGroupLink.create cn: 'example', group_access: Gitlab::Access::DEVELOPER, group_id: 42
      Gitlab::LDAP::Adapter.any_instance.stub(:group) { Gitlab::LDAP::Group.new(ldap_group_1) }

      expect(access.ldap_groups.first).to be_a Gitlab::LDAP::Group
    end

    it "only returns found ldap groups" do
      ::LdapGroupLink.create cn: 'example', group_access: Gitlab::Access::DEVELOPER, group_id: 42
      Gitlab::LDAP::Group.stub(find_by_cn: nil) # group not found

      expect(access.ldap_groups).to be_empty
    end
  end

  describe :cns_with_access do
    let(:ldap_group_response_1) do
      Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=group1,ou=groups,dc=bar,dc=com
cn: group1
description: GitLab group 1
gidnumber: 21
memberuid: #{ldap_user.uid}
memberuid: user2
objectclass: top
objectclass: posixGroup
})
    end
    let(:ldap_group_response_2) do
      Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=group2,ou=groups,dc=bar,dc=com
cn: group2
description: GitLab group 2
gidnumber: 42
memberuid: user3
memberuid: user4
objectclass: top
objectclass: posixGroup
})
    end
    let(:ldap_groups) do
      [
        Gitlab::LDAP::Group.new(ldap_group_response_1),
        Gitlab::LDAP::Group.new(ldap_group_response_2)
      ]
    end
    let(:ldap_user) { Gitlab::LDAP::Person.new(Net::LDAP::Entry.new, user.provider) }

    before do
      access.stub(ldap_user: ldap_user)
      ldap_user.stub(:uid) { 'user42' }
    end

    it "only returns ldap cns to which the user has access" do
      access.stub(ldap_groups: ldap_groups)
      expect(access.cns_with_access).to eql ['group1']
    end
  end
end

