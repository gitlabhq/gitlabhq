require 'spec_helper'

describe LdapGroupSyncWorker do
  describe '#perform' do
    it 'syncs all groups when group_id is nil' do
      expect(EE::Gitlab::LDAP::Sync::Groups).to receive(:execute)

      described_class.new.perform
    end

    it 'syncs a single group when group_id is present' do
      group = create(:group)

      expect(EE::Gitlab::LDAP::Sync::Group)
        .to receive(:execute_all_providers).with(group)

      described_class.new.perform(group.id)
    end

    it 'logs an error when group cannot be found' do
      expect(EE::Gitlab::LDAP::Sync::Group).not_to receive(:execute_all_providers)
      expect(Sidekiq.logger)
        .to receive(:warn).with('Could not find group 9999 for LDAP group sync')

      described_class.new.perform(9999)
    end
  end
end
