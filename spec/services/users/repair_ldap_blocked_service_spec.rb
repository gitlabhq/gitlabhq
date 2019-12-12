# frozen_string_literal: true

require 'spec_helper'

describe Users::RepairLdapBlockedService do
  let(:user) { create(:omniauth_user, provider: 'ldapmain', state: 'ldap_blocked') }
  let(:identity) { user.ldap_identity }

  subject(:service) { described_class.new(user) }

  describe '#execute' do
    it 'changes to normal block after destroying last ldap identity' do
      identity.destroy
      service.execute

      expect(user.reload).not_to be_ldap_blocked
    end

    it 'changes to normal block after changing last ldap identity to another provider' do
      identity.update_attribute(:provider, 'twitter')
      service.execute

      expect(user.reload).not_to be_ldap_blocked
    end
  end
end
