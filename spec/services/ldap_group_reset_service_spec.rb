require 'spec_helper'

describe LdapGroupResetService do
  # TODO: refactor to multi-ldap setup
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:ldap_user) { create(:omniauth_user, extern_uid: 'john', provider: 'ldap', last_credential_check_at: Time.now) }
  let(:ldap_user_2) { create(:omniauth_user, extern_uid: 'mike', provider: 'ldap', last_credential_check_at: Time.now) }

  before do
    group.add_owner(user)
    group.add_owner(ldap_user)
    group.add_user(ldap_user_2, Gitlab::Access::REPORTER)
    group.ldap_group_links.create cn: 'developers', group_access: Gitlab::Access::DEVELOPER
  end

  describe '#execute' do
    context 'initiated by ldap user' do
      before do
        described_class.new.execute(group, ldap_user)
      end

      it { expect(member_access(ldap_user)).to eq Gitlab::Access::OWNER }
      it { expect(member_access(ldap_user_2)).to eq Gitlab::Access::GUEST }
      it { expect(member_access(user)).to eq Gitlab::Access::OWNER }
      it { expect(ldap_user.reload.last_credential_check_at).to be_nil }
      it { expect(ldap_user_2.reload.last_credential_check_at).to be_nil }
    end

    context 'initiated by regular user' do
      before do
        described_class.new.execute(group, user)
      end

      it { expect(member_access(ldap_user)).to eq Gitlab::Access::GUEST }
      it { expect(member_access(ldap_user_2)).to eq Gitlab::Access::GUEST }
      it { expect(member_access(user)).to eq Gitlab::Access::OWNER }
      it { expect(ldap_user.reload.last_credential_check_at).to be_nil }
      it { expect(ldap_user_2.reload.last_credential_check_at).to be_nil }
    end
  end

  def member_access(user)
    group.members.find_by(user_id: user).access_level
  end
end
