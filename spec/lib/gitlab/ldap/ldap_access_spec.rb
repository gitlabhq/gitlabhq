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

    it "should update the email if the user email is different" do
      entry = Net::LDAP::Entry.new
      entry['mail'] = ["new_email@example.com"]
      Gitlab::LDAP::Adapter.any_instance.stub(:user) { Gitlab::LDAP::Person.new(entry) }
      updated = access.update_email(user_ldap)
      updated.should == true
    end
  end
end
