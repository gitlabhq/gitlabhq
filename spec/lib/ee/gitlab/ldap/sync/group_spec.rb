require 'spec_helper'

describe EE::Gitlab::LDAP::Sync::Group, lib: true do
  include LdapHelpers

  let(:adapter) { ldap_adapter }
  let(:user) { create(:user) }

  before do
    # We need to actually activate the LDAP config otherwise `Group#ldap_synced?`
    # will always be false!
    allow(Gitlab.config.ldap).to receive_messages(enabled: true)

    create(:identity, user: user, extern_uid: user_dn(user.username))

    stub_ldap_config(active_directory: false)
    stub_ldap_group_find_by_cn('ldap_group1', ldap_group1, adapter)
  end

  shared_examples :group_state_machine do
    it 'uses the ldap sync state machine' do
      expect(group).to receive(:start_ldap_sync)
      expect(group).to receive(:finish_ldap_sync)
      expect(EE::Gitlab::LDAP::Sync::Group)
        .to receive(:new).at_most(:twice).and_call_original

      execute
    end

    it 'fails a stuck group older than 1 hour' do
      group.start_ldap_sync
      group.update_column(:ldap_sync_last_sync_at, 61.minutes.ago)

      expect(group).to receive(:mark_ldap_sync_as_failed)

      execute
    end

    context 'when the group ldap sync is already started' do
      it 'logs a debug message' do
        group.start_ldap_sync

        expect(Rails.logger)
          .to receive(:warn)
                .with(/^Group '\w*' is not ready for LDAP sync. Skipping/)
                .at_least(:once)

        execute
      end

      it 'does not update permissions' do
        group.start_ldap_sync

        expect_any_instance_of(EE::Gitlab::LDAP::Sync::Group)
          .not_to receive(:update_permissions)

        execute
      end
    end
  end

  describe '.execute_all_providers' do
    def execute
      described_class.execute_all_providers(group)
    end

    before do
      allow(Gitlab::LDAP::Config)
        .to receive(:providers).and_return(['main', 'secondary'])
      allow(EE::Gitlab::LDAP::Sync::Proxy)
        .to receive(:open).and_yield(double('proxy').as_null_object)
    end

    let(:group) do
      create(:group_with_ldap_group_link,
             cn: 'ldap_group1',
             group_access: ::Gitlab::Access::DEVELOPER)
    end
    let(:ldap_group1) { ldap_group_entry(user_dn(user.username)) }

    include_examples :group_state_machine
  end

  describe '.execute' do
    def execute
      described_class.execute(group, proxy(adapter))
    end

    let(:group) do
      create(:group_with_ldap_group_link,
             cn: 'ldap_group1',
             group_access: ::Gitlab::Access::DEVELOPER)
    end
    let(:ldap_group1) { ldap_group_entry(user_dn(user.username)) }

    include_examples :group_state_machine
  end

  describe '.ldap_sync_ready?' do
    let(:ldap_group1) { nil }

    it 'returns false when ldap sync started' do
      group = create(:group)
      group.start_ldap_sync

      expect(described_class.ldap_sync_ready?(group)).to be_falsey
    end

    it 'returns true when ldap sync pending' do
      group = create(:group)
      group.pending_ldap_sync

      expect(described_class.ldap_sync_ready?(group)).to be_truthy
    end
  end

  describe '#update_permissions' do
    before do
      # Safe-check because some permissions are removed when `Group#ldap_synced?`
      # is true (e.g. in `GroupPolicy`).
      expect(group).to be_ldap_synced
      group.start_ldap_sync
    end
    after do
      group.finish_ldap_sync
    end

    let(:group) do
      create(:group_with_ldap_group_link, :access_requestable,
             cn: 'ldap_group1',
             group_access: ::Gitlab::Access::DEVELOPER)
    end
    let(:sync_group) { described_class.new(group, proxy(adapter)) }

    context 'with all functionality against one LDAP group type' do
      context 'with basic add/update actions' do
        let(:ldap_group1) { ldap_group_entry(user_dn(user.username)) }

        it 'does not update permissions unless ldap sync status is started' do
          group.finish_ldap_sync

          expect(Rails.logger)
            .to receive(:warn).with(/status must be 'started' before updating permissions/)

          sync_group.update_permissions
        end

        it 'adds new members and sets ldap attribute to true' do
          sync_group.update_permissions

          expect(group.members.pluck(:user_id)).to include(user.id)
          expect(group.members.find_by(user_id: user.id).ldap?).to be_truthy
        end

        it 'converts an existing membership access request to a real member' do
          group.add_owner(create(:user))
          access_requester = group.request_access(user)
          access_requester.update(access_level: ::Gitlab::Access::MASTER)
          # Validate that the user is properly created as a requester first.
          expect(group.requesters.pluck(:id)).to include(access_requester.id)

          sync_group.update_permissions

          expect(group.members.pluck(:id)).to include(access_requester.id)
          expect(group.members.find_by(user_id: user.id).access_level)
            .to eq(::Gitlab::Access::DEVELOPER)
        end

        it 'downgrades existing member access' do
          # Create user with higher access
          group.add_user(user, Gitlab::Access::MASTER)

          sync_group.update_permissions

          expect(group.members.find_by(user_id: user.id).access_level)
            .to eq(::Gitlab::Access::DEVELOPER)
        end

        it 'upgrades existing member access' do
          # Create user with lower access
          group.add_user(user, Gitlab::Access::GUEST)

          sync_group.update_permissions

          expect(group.members.find_by(user_id: user.id).access_level)
            .to eq(::Gitlab::Access::DEVELOPER)
        end

        it 'sets an existing member ldap attribute to true' do
          group.add_users(
            [user],
            ::Gitlab::Access::DEVELOPER
          )

          sync_group.update_permissions

          expect(group.members.find_by(user_id: user.id).ldap?).to be_truthy
        end

        it 'does not alter an ldap member that has a permission override' do
          group.members.create(
            user: user,
            access_level: ::Gitlab::Access::MASTER,
            ldap: true,
            override: true
          )

          sync_group.update_permissions

          expect(group.members.find_by(user_id: user.id).access_level)
            .to eq(::Gitlab::Access::MASTER)
        end
      end

      context 'when existing user is no longer in LDAP group' do
        let(:ldap_group1) do
          ldap_group_entry(user_dn('some_user'))
        end

        it 'removes the user from the group' do
          group.add_user(user, Gitlab::Access::MASTER)

          sync_group.update_permissions

          expect(group.members.find_by(user_id: user.id)).to be_nil
        end

        it 'refuses to delete the last owner' do
          group.add_user(user, Gitlab::Access::OWNER)

          sync_group.update_permissions

          expect(group.members.find_by(user_id: user.id).access_level)
            .to eq(::Gitlab::Access::OWNER)
        end
      end

      context 'when the user is the last owner' do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }
        let(:ldap_group1) do
          ldap_group_entry(%W(#{user_dn(user1.username)} #{user_dn(user2.username)}))
        end

        it 'downgrades one user but not the other' do
          create(:identity, user: user1, extern_uid: user_dn(user1.username))
          create(:identity, user: user2, extern_uid: user_dn(user2.username))
          group.add_users([user1, user2], Gitlab::Access::OWNER)

          sync_group.update_permissions

          expect(group.members.pluck(:access_level).sort)
            .to eq([::Gitlab::Access::DEVELOPER, ::Gitlab::Access::OWNER])
        end
      end
    end

    # Test that membership can be resolved for all different type of LDAP groups
    context 'with different LDAP group types' do
      # GroupOfNames - OpenLDAP
      context 'with groupOfNames style LDAP group' do
        let(:ldap_group1) do
          ldap_group_entry(
            user_dn(user.username),
            objectclass: 'groupOfNames',
            member_attr: 'uniqueMember'
          )
        end

        it 'adds the user to the group' do
          sync_group.update_permissions

          expect(group.members.pluck(:user_id)).to include(user.id)
        end
      end

      # posixGroup - Apple Open Directory
      context 'with posixGroup style LDAP group' do
        let(:ldap_group1) do
          ldap_group_entry(
            user.username,
            objectclass: 'posixGroup',
            member_attr: 'memberUid'
          )
        end
        let(:ldap_user) do
          ldap_user_entry(user.username)
        end

        it 'adds the user to the group' do
          stub_ldap_person_find_by_uid(user.username, ldap_user)

          sync_group.update_permissions

          expect(group.members.pluck(:user_id)).to include(user.id)
        end
      end

      context 'with groupOfUniqueNames style LDAP group' do
        let(:ldap_group1) do
          ldap_group_entry(
            user_dn(user.username),
            objectclass: 'groupOfUniqueNames',
            member_attr: 'uniqueMember'
          )
        end

        it 'adds the user to the group' do
          sync_group.update_permissions

          expect(group.members.pluck(:user_id)).to include(user.id)
        end
      end

      context 'with an empty LDAP group' do
        let(:ldap_group1) do
          ldap_group_entry(nil)
        end

        it 'does nothing, without failure' do
          expect { sync_group.update_permissions }
            .not_to change { group.members.count }
        end
      end
    end
  end
end
