require 'spec_helper'

describe Gitlab::LDAP::Access do
  let(:access) { Gitlab::LDAP::Access.new }
  let(:user) { create(:user) }
  let(:group) { create(:group, ldap_cn: 'oss', ldap_access: Gitlab::Access::DEVELOPER) }

  before do
    group
  end

  describe :add_user_to_groups do
    it "should add user to group" do
      access.add_user_to_groups(user.id, "oss")
      member = group.members.first
      member.user.should == user
      member.group_access.should == Gitlab::Access::DEVELOPER
    end

    it "should respect higher permissions" do
      group.add_owner(user)
      access.add_user_to_groups(user.id, "oss")
      group.owners.should include(user)
    end

    it "should update lower permissions" do
      group.add_user(user, Gitlab::Access::REPORTER)
      access.add_user_to_groups(user.id, "oss")
      member = group.members.first
      member.user.should == user
      member.group_access.should == Gitlab::Access::DEVELOPER
    end
  end

  describe :update_user_email do
    let(:user_ldap) { create(:user, provider: 'ldap', extern_uid: "66048")}

    it "should not update email if email attribute is not set" do
      entry = Net::LDAP::Entry.new
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
      updated = access.update_email(user_ldap)
      updated.should == false
    end

    it "should not update the email if the user has the same email in GitLab and in LDAP" do
      entry = Net::LDAP::Entry.new
      entry['mail'] = [user_ldap.email]
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
      updated = access.update_email(user_ldap)
      updated.should == false
    end

    it "should not update the email if the user has the same email GitLab and in LDAP, but with upper case in LDAP" do
      entry = Net::LDAP::Entry.new
      entry['mail'] = [user_ldap.email.upcase]
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
      updated = access.update_email(user_ldap)
      updated.should == false
    end

    it "should update the email if the user email is different" do
      entry = Net::LDAP::Entry.new
      entry['mail'] = ["new_email@example.com"]
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
      updated = access.update_email(user_ldap)
      updated.should == true
    end
  end

  describe :update_ssh_keys do
    let(:user_ldap) { create(:user, provider: 'ldap', extern_uid: "66049")}
    let(:ssh_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj' }
    let(:key_ldap) { LDAPKey.new(title: 'used to be a ldap key', key: ssh_key) }

    before do
      @old_value = Gitlab.config.ldap['sync_ssh_keys']
      key_attribute_name = 'sshpublickey'
      Gitlab.config.ldap['sync_ssh_keys'] = key_attribute_name
    end

    after do
      Gitlab.config.ldap['sync_ssh_keys'] = @old_value
    end

    it "should add a SSH key if it is in LDAP but not in gitlab" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{Gitlab.config.ldap['sync_ssh_keys']}: #{ssh_key}")
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }

      expect(user_ldap.keys.size).to be(0)
      access.update_ssh_keys(user_ldap)
      expect(user_ldap.keys.size).to be(1)
    end

    it "should add a SSH key and give it a proper name" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{Gitlab.config.ldap['sync_ssh_keys']}: #{ssh_key}")
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }

      access.update_ssh_keys(user_ldap)
      expect(user_ldap.keys.last.title).to match(/LDAP/)
      expect(user_ldap.keys.last.title).to match(/#{Gitlab.config.ldap['sync_ssh_keys']}/)
    end

    it "should not add a SSH key if it is invalid" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{Gitlab.config.ldap['sync_ssh_keys']}: I am not a valid key")
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }

      expect(user_ldap.keys.size).to be(0)
      access.update_ssh_keys(user_ldap)
      expect(user_ldap.keys.size).to be(0)
    end

    context 'user has at least one LDAPKey' do

      it "should remove a SSH key if it is no longer in LDAP" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{Gitlab.config.ldap['sync_ssh_keys']}:\n")
        Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
        key_ldap.save
        user_ldap.keys << key_ldap

        expect(user_ldap.keys.size).to be(1)
        access.update_ssh_keys(user_ldap)
        expect(user_ldap.keys.size).to be(0)
      end

      it "should remove a SSH key if the ldap attribute was removes" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
        Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
        key_ldap.save
        user_ldap.keys << key_ldap
        expect(user_ldap.keys.size).to be(1)
        access.update_ssh_keys(user_ldap)
        expect(user_ldap.keys.size).to be(0)
      end
    end

  end

  describe :allowed? do
    subject { access.allowed?(user) }

    context 'when the user cannot be found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: nil) }

      it { should be_false }
    end

    context 'when the user is found' do
      before { Gitlab::LDAP::Person.stub(find_by_dn: :ldap_user) }

      context 'and the Active Directory disabled flag is set' do
        before { Gitlab::LDAP::Person.stub(active_directory_disabled?: true) }

        it { should be_false }
      end

      context 'and the Active Directory disabled flag is not set' do
        before { Gitlab::LDAP::Person.stub(active_directory_disabled?: false) }

        it { should be_true }
      end
    end
  end

  describe :update_admin_status do
    let(:gitlab_user) { create(:user, provider: 'ldap', extern_uid: "admin2")}
    let(:gitlab_admin) { create(:admin, provider: 'ldap', extern_uid: "admin2")}

    before do
      Gitlab.config.ldap['admin_group'] = "GLAdmins"
      ldap_user_entry = Net::LDAP::Entry.new
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(ldap_user_entry) }
      Gitlab::LDAP::Person.any_instance.stub(:uid) { 'admin2' }
    end

    it "should give admin privileges to an User" do
      admin_group = Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=#{Gitlab.config.ldap['admin_group']},ou=groups,dc=bar,dc=com
cn: #{Gitlab.config.ldap['admin_group']}
description: GitLab admins
gidnumber: 42
memberuid: admin1
memberuid: admin2
memberuid: admin3
objectclass: top
objectclass: posixGroup
})
      Gitlab::LDAP::Adapter.any_instance.stub(:group) { Gitlab::LDAP::Group.new(admin_group) }
      expect(gitlab_user.admin?).to be false
      access.update_admin_status(gitlab_user)
      expect(gitlab_user.admin?).to be true
    end

    it "should remove admin privileges from an User" do
      admin_group = Net::LDAP::Entry.from_single_ldif_string(
%Q{dn: cn=#{Gitlab.config.ldap['admin_group']},ou=groups,dc=bar,dc=com
cn: #{Gitlab.config.ldap['admin_group']}
description: GitLab admins
gidnumber: 42
memberuid: admin1
memberuid: admin3
objectclass: top
objectclass: posixGroup
})
      Gitlab::LDAP::Adapter.any_instance.stub(:group) { Gitlab::LDAP::Group.new(admin_group) }
      expect(gitlab_admin.admin?).to be true
      access.update_admin_status(gitlab_admin)
      expect(gitlab_admin.admin?).to be false
    end
  end
end
