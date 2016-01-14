require 'spec_helper'

describe RepairLdapBlockedUserService, services: true do
  let(:user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }
  let(:identity) { user.ldap_identity }
  subject(:service) { RepairLdapBlockedUserService.new(user) }

  describe '#execute' do
    it 'change to normal block after destroying last ldap identity' do
      identity.destroy
      service.execute

      expect(user.reload).not_to be_ldap_blocked
    end

    it 'change to normal block after changing last ldap identity to another provider' do
      identity.update_attribute(:provider, 'twitter')
      service.execute

      expect(user.reload).not_to be_ldap_blocked
    end
  end
end
