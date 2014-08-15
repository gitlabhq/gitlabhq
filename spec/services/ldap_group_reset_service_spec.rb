require 'spec_helper'

describe LdapGroupResetService do
  # TODO: refactor to multi-ldap setup
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:ldap_user) { create(:user, extern_uid: 'john', provider: 'ldap', last_credential_check_at: Time.now) }
  let(:ldap_user_2) { create(:user, extern_uid: 'mike', provider: 'ldap', last_credential_check_at: Time.now) }

  before do
    group.add_owner(user)
    group.add_owner(ldap_user)
    group.add_user(ldap_user_2, Gitlab::Access::REPORTER)
    group.ldap_group_links.create cn: 'developers', group_access: Gitlab::Access::DEVELOPER
  end

  describe '#execute' do
    context 'initiated by ldap user' do
      before { LdapGroupResetService.new.execute(group, ldap_user) }

      it { member_access(ldap_user).should == Gitlab::Access::OWNER }
      it { member_access(ldap_user_2).should == Gitlab::Access::GUEST }
      it { member_access(user).should == Gitlab::Access::OWNER }
      it { expect(ldap_user.reload.last_credential_check_at).to be_nil }
      it { expect(ldap_user_2.reload.last_credential_check_at).to be_nil }
    end

    context 'initiated by regular user' do
      before { LdapGroupResetService.new.execute(group, user) }

      it { member_access(ldap_user).should == Gitlab::Access::GUEST }
      it { member_access(ldap_user_2).should == Gitlab::Access::GUEST }
      it { member_access(user).should == Gitlab::Access::OWNER }
      it { expect(ldap_user.reload.last_credential_check_at).to be_nil }
      it { expect(ldap_user_2.reload.last_credential_check_at).to be_nil }
    end
  end

  def member_access(user)
    group.members.find_by(user_id: user).group_access
  end
end
