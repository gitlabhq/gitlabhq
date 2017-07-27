require 'spec_helper'

describe EE::Gitlab::LDAP::Sync::Groups do
  include LdapHelpers

  let(:adapter) { ldap_adapter }
  let(:group_sync) { described_class.new(proxy(adapter)) }

  describe '#update_permissions' do
    before do
      allow(EE::Gitlab::LDAP::Sync::Group).to receive(:execute)
      allow(EE::Gitlab::LDAP::Sync::AdminUsers).to receive(:execute)
      allow(EE::Gitlab::LDAP::Sync::ExternalUsers).to receive(:execute)

      2.times { create(:group_with_ldap_group_link) }
    end

    after do
      group_sync.update_permissions
    end

    context 'when group_base is not present' do
      before do
        stub_ldap_config(group_base: nil)
      end

      it 'does not call EE::Gitlab::LDAP::Sync::Group#execute' do
        expect(EE::Gitlab::LDAP::Sync::Group).not_to receive(:execute)
      end

      it 'does not call EE::Gitlab::LDAP::Sync::AdminUsers#execute' do
        expect(EE::Gitlab::LDAP::Sync::AdminUsers).not_to receive(:execute)
      end

      it 'does not call EE::Gitlab::LDAP::Sync::ExternalUsers#execute' do
        expect(EE::Gitlab::LDAP::Sync::ExternalUsers).not_to receive(:execute)
      end
    end

    context 'when group_base is present' do
      context 'and admin_group and external_groups are not present' do
        before do
          stub_ldap_config(group_base: 'dc=example,dc=com')
        end

        it 'calls EE::Gitlab::LDAP::Sync::Group#execute' do
          expect(EE::Gitlab::LDAP::Sync::Group).to receive(:execute).twice
        end

        it 'does not call EE::Gitlab::LDAP::Sync::AdminUsers#execute' do
          expect(EE::Gitlab::LDAP::Sync::AdminUsers).not_to receive(:execute)
        end

        it 'does not call EE::Gitlab::LDAP::Sync::ExternalUsers#execute' do
          expect(EE::Gitlab::LDAP::Sync::ExternalUsers).not_to receive(:execute)
        end
      end

      context 'and admin_group is present' do
        before do
          stub_ldap_config(
            group_base: 'dc=example,dc=com',
            admin_group: 'my-admin-group'
          )
        end

        it 'calls EE::Gitlab::LDAP::Sync::Group#execute' do
          expect(EE::Gitlab::LDAP::Sync::Group).to receive(:execute).twice
        end

        it 'does not call EE::Gitlab::LDAP::Sync::AdminUsers#execute' do
          expect(EE::Gitlab::LDAP::Sync::AdminUsers).to receive(:execute).once
        end

        it 'does not call EE::Gitlab::LDAP::Sync::ExternalUsers#execute' do
          expect(EE::Gitlab::LDAP::Sync::ExternalUsers).not_to receive(:execute)
        end
      end

      context 'and external_groups is present' do
        before do
          stub_ldap_config(
            group_base: 'dc=example,dc=com',
            external_groups: %w(external_group)
          )
        end

        it 'calls EE::Gitlab::LDAP::Sync::Group#execute' do
          expect(EE::Gitlab::LDAP::Sync::Group).to receive(:execute).twice
        end

        it 'does not call EE::Gitlab::LDAP::Sync::AdminUsers#execute' do
          expect(EE::Gitlab::LDAP::Sync::AdminUsers).not_to receive(:execute)
        end

        it 'does not call EE::Gitlab::LDAP::Sync::ExternalUsers#execute' do
          expect(EE::Gitlab::LDAP::Sync::ExternalUsers).to receive(:execute).once
        end
      end
    end
  end
end
