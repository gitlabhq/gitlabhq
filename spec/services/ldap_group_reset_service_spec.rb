require 'spec_helper'

describe LdapGroupResetService do
  # TODO: refactor to multi-ldap setup
  let(:group) { create(:group, ldap_cn: 'developers', ldap_access: Gitlab::Access::DEVELOPER) }
  let(:user) { create(:user) }
  let(:ldap_user) { create(:user, extern_uid: 'john', provider: 'ldap') }
  let(:ldap_user_2) { create(:user, extern_uid: 'mike', provider: 'ldap') }

  before do
    group.add_owner(user)
    group.add_owner(ldap_user)
    group.add_user(ldap_user_2, Gitlab::Access::REPORTER)
  end

  describe '#execute' do
    context 'initiated by ldap user' do
      before { LdapGroupResetService.new.execute(group, ldap_user) }

      it { member_access(ldap_user).should == Gitlab::Access::OWNER }
      it { member_access(ldap_user_2).should == Gitlab::Access::DEVELOPER }
      it { member_access(user).should == Gitlab::Access::OWNER }
    end

    context 'initiated by regular user' do
      before { LdapGroupResetService.new.execute(group, user) }

      it { member_access(ldap_user).should == Gitlab::Access::DEVELOPER }
      it { member_access(ldap_user_2).should == Gitlab::Access::DEVELOPER }
      it { member_access(user).should == Gitlab::Access::OWNER }
    end
  end

  def member_access(user)
    group.members.find_by(user_id: user).group_access
  end
end
