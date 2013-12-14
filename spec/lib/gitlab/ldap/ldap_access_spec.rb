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
end
