require 'spec_helper'

describe Gitlab::LDAP::GroupSync, lib: true do
  let(:group_sync) { Gitlab::LDAP::GroupSync.new('ldapmain') }
  let(:config) { double(:config, active_directory: false) }
  let(:adapter) { double(:adapter, config: config) }
  subject { group_sync }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease)
      .to receive(:try_obtain).and_return(true)
  end

  describe '#update_permissions' do
    before do
      allow(group_sync)
        .to receive_messages(sync_groups: true, sync_admin_users: true)
    end
    after { group_sync.update_permissions }

    context 'when group_base is present but admin_group is not' do
      before do
        allow(group_sync)
          .to receive_messages(group_base: 'my-group-base', admin_group: nil)
      end

      it { is_expected.to receive(:sync_groups) }
      it { is_expected.not_to receive(:sync_admin_users) }
    end

    context 'when admin_group is present but group_base is not' do
      before do
        allow(group_sync)
          .to receive_messages(group_base: nil, admin_group: 'my-admin-group')
      end

      it { is_expected.to receive(:sync_admin_users) }
      it { is_expected.not_to receive(:sync_groups) }
    end
  end

  describe '#sync_groups' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:group1) { create(:group) }
    let(:group2) { create(:group) }
    let(:ldap_group1) do
      Net::LDAP::Entry.from_single_ldif_string(
        <<-EOS.strip_heredoc
          dn: cn=ldap_group1,ou=groups,dc=example,dc=com
          cn: ldap_group1
          description: LDAP Group 1
          gidnumber: 42
          uniqueMember: uid=#{user1.username},ou=users,dc=example,dc=com
          uniqueMember: uid=#{user2.username},ou=users,dc=example,dc=com
          objectclass: top
          objectclass: groupOfNames
        EOS
      )
    end

    context 'with all functionality against one LDAP group type' do
      before do
        allow_any_instance_of(Gitlab::LDAP::Group)
          .to receive(:adapter).and_return(adapter)

        user1.identities.create(
          provider: 'ldapmain',
          extern_uid: "uid=#{user1.username},ou=users,dc=example,dc=com"
        )
        user2.identities.create(
          provider: 'ldapmain',
          extern_uid: "uid=#{user2.username},ou=users,dc=example,dc=com"
        )

        allow(Gitlab::LDAP::Group)
          .to receive(:find_by_cn)
            .with('ldap_group1', kind_of(Gitlab::LDAP::Adapter))
            .and_return(Gitlab::LDAP::Group.new(ldap_group1))

        group1.ldap_group_links.create(
          cn: 'ldap_group1',
          group_access: Gitlab::Access::DEVELOPER,
          provider: 'ldapmain'
        )
        group2.ldap_group_links.create(
          cn: 'ldap_group1',
          group_access: Gitlab::Access::OWNER,
          provider: 'ldapmain'
        )
      end

      context 'with basic add/update actions' do
        before do
          # Pre-populate the group with some users
          group1.add_users([user1.id],
                           Gitlab::Access::MASTER, skip_notification: true)
          group2.add_users([user2.id],
                           Gitlab::Access::DEVELOPER, skip_notification: true)
        end

        it 'adds new members' do
          expect { group_sync.sync_groups }
            .to change { group1.members.where(user_id: user2.id).any? }
              .from(false).to(true)
        end

        it 'downgrades existing member access' do
          expect { group_sync.sync_groups }
            .to change {
              group1.members.where(
                user_id: user1.id,
                access_level: Gitlab::Access::DEVELOPER
              ).any?
            }.from(false).to(true)
        end

        it 'upgrades existing member access' do
          expect { group_sync.sync_groups }
            .to change {
              group2.members.where(
                user_id: user2.id,
                access_level: Gitlab::Access::OWNER
              ).any?
            }.from(false).to(true)
        end

        it 'does not send a notification email' do
          expect { group_sync.sync_groups }
            .not_to change { ActionMailer::Base.deliveries }
        end
      end

      context 'when existing user is no longer in LDAP group' do
        let(:user_without_group) { create(:user) }
        before do
          user_without_group.identities
            .create(provider: group_sync.provider,
                    extern_uid: "uid=johndoe,ou=users,dc=example,dc=com" )
          group1.add_users([user_without_group.id],
                           Gitlab::Access::MASTER, skip_notification: true)
          group2.add_users([user_without_group.id],
                           Gitlab::Access::OWNER, skip_notification: true)
        end

        it 'removes the user from the group' do
          expect { group_sync.sync_groups }
            .to change { group1.members.where(user_id: user_without_group.id).any? }
              .from(true).to(false)
        end

        it 'refuses to delete the last owner' do
          expect { group_sync.sync_groups }
            .not_to change { group2.members.where(user_id: user_without_group.id).any? }
        end
      end

      context 'when user is the last owner' do
        before do
          group1.ldap_group_links.create(
            cn: 'ldap_group1',
            group_access: Gitlab::Access::DEVELOPER,
            provider: 'ldapmain'
          )
          group1.add_users([user1.id],
            Gitlab::Access::OWNER, skip_notification: true)
        end

        it 'refuses to downgrade the last owner' do
          expect { group_sync.sync_groups }
            .not_to change {
              group1.members.where(
                user_id: user1.id,
                access_level: Gitlab::Access::OWNER
              ).any?
            }
        end

        context 'when user is a member of two groups from different providers' do
          let(:config) { double(:config, active_directory: false, provider: 'ldapsecondary') }
          let(:adapter) { double(:adapter, config: config) }
          let(:secondary_group_sync) do
            Gitlab::LDAP::GroupSync.new('ldapsecondary', adapter)
          end
          let(:ldap_secondary_group1) do
            Net::LDAP::Entry.from_single_ldif_string(
              <<-EOS.strip_heredoc
                dn: cn=ldap_secondary_group1,ou=groups,dc=example,dc=com
                cn: ldap_secondary_group1
                description: LDAP Group 1
                gidnumber: 42
                uniqueMember: uid=#{user1.username},ou=users,dc=example,dc=com
                uniqueMember: uid=#{user2.username},ou=users,dc=example,dc=com
                objectclass: top
                objectclass: groupOfNames
              EOS
            )
          end
          let(:user_w_multiple_ids) { create(:user) }

          before do
            allow(Gitlab::LDAP::Group)
              .to receive(:find_by_cn)
                .with('ldap_group1', any_args)
                .and_return(Gitlab::LDAP::Group.new(ldap_group1))
            allow(Gitlab::LDAP::Group)
              .to receive(:find_by_cn)
                .with('ldap_secondary_group1', any_args)
                .and_return(Gitlab::LDAP::Group.new(ldap_secondary_group1))
            user_w_multiple_ids.identities.create(
              [
                {
                  provider: 'ldapsecondary',
                  extern_uid: "uid=#{user1.username},ou=users,dc=example,dc=com"
                },
                {
                  provider: 'ldapprimary',
                  extern_uid: "uid=#{user1.username},ou=users,dc=example,dc=com"
                }
              ]
            )
            group1.ldap_group_links.create(
              cn: 'ldap_group1',
              group_access: Gitlab::Access::DEVELOPER,
              provider: 'ldapprimary'
            )
            group1.ldap_group_links.create(
              cn: 'ldap_secondary_group1',
              group_access: Gitlab::Access::OWNER,
              provider: 'ldapsecondary'
            )
            group1.add_users([user_w_multiple_ids.id],
                             Gitlab::Access::DEVELOPER, skip_notification: true)
          end

          it 'does not change user permissions for secondary group link' do
            expect { secondary_group_sync.sync_groups }
              .not_to change {
                group1.members.where(
                  user_id: user_w_multiple_ids.id,
                  access_level: Gitlab::Access::OWNER
                ).any?
              }
          end
        end
      end

      context 'when access level spillover could happen' do
        it 'does not erroneously add users' do
          ldap_group2 = Net::LDAP::Entry.from_single_ldif_string(
            <<-EOS.strip_heredoc
              dn: cn=ldap_group2,ou=groups,dc=example,dc=com
              cn: ldap_group2
              description: LDAP Group 2
              gidnumber: 55
              uniqueMember: uid=#{user2.username},ou=users,dc=example,dc=com
              objectclass: top
              objectclass: groupOfNames
            EOS
          )

          allow_any_instance_of(Gitlab::LDAP::Group)
            .to receive(:adapter).and_return(adapter)

          user1.identities.create(
            provider: 'ldapmain',
            extern_uid: "uid=#{user1.username},ou=users,dc=example,dc=com"
          )
          user2.identities.create(
            provider: 'ldapmain',
            extern_uid: "uid=#{user2.username},ou=users,dc=example,dc=com"
          )

          allow(Gitlab::LDAP::Group)
            .to receive(:find_by_cn)
              .with('ldap_group1', kind_of(Gitlab::LDAP::Adapter))
              .and_return(Gitlab::LDAP::Group.new(ldap_group1))
          allow(Gitlab::LDAP::Group)
            .to receive(:find_by_cn)
              .with('ldap_group2', kind_of(Gitlab::LDAP::Adapter))
              .and_return(Gitlab::LDAP::Group.new(ldap_group2))

          group1.members.destroy_all
          group1.ldap_group_links.destroy_all
          group1.ldap_group_links.create(
            cn: 'ldap_group1',
            group_access: Gitlab::Access::DEVELOPER,
            provider: 'ldapmain'
          )
          group2.members.destroy_all
          group2.ldap_group_links.destroy_all
          group2.ldap_group_links.create(
            cn: 'ldap_group2',
            group_access: Gitlab::Access::MASTER,
            provider: 'ldapmain'
          )

          group_sync.sync_groups

          expect(group1.members.pluck(:user_id).sort).to eq([user1.id, user2.id].sort)
          expect(group1.members.pluck(:access_level).uniq).to eq([Gitlab::Access::DEVELOPER])
          expect(group2.members.pluck(:user_id)).to eq([user2.id])
          expect(group2.members.pluck(:access_level).uniq).to eq([Gitlab::Access::MASTER])
        end
      end
    end

    # Test that membership can be resolved for all different type of LDAP groups
    context 'with different LDAP group types' do
      let(:secondary_extern_uid) { nil }

      before do
        allow_any_instance_of(Gitlab::LDAP::Group)
          .to receive(:adapter).and_return(adapter)
        allow(Gitlab::LDAP::Group)
          .to receive(:find_by_cn)
            .with(ldap_group.cn, any_args)
            .and_return(ldap_group)
        user1.identities.create(
          provider: 'ldapmain',
          extern_uid: "uid=#{user1.username},ou=users,dc=example,dc=com",
          secondary_extern_uid: secondary_extern_uid
        )
        group1.ldap_group_links.create(
          cn: ldap_group.cn,
          group_access: Gitlab::Access::DEVELOPER,
          provider: 'ldapmain'
        )
      end

      # GroupOfNames - OpenLDAP
      context 'with groupOfNames style LDAP group' do
        let(:ldap_group) do
          Gitlab::LDAP::Group.new(
            Net::LDAP::Entry.from_single_ldif_string(
              <<-EOS.strip_heredoc
                dn: cn=ldap_group1,ou=groups,dc=example,dc=com
                cn: ldap_group1
                description: LDAP Group 1
                member: uid=#{user1.username},ou=users,dc=example,dc=com
                objectclass: top
                objectclass: groupOfNames
              EOS
            )
          )
        end

        it 'adds the user to the group' do
          expect { group_sync.sync_groups }
            .to change { group1.members.where(user_id: user1.id).any? }
              .from(false).to(true)
        end
      end

      # posixGroup - Apple Open Directory
      context 'with posixGroup style LDAP group' do
        let(:ldap_group) do
          Gitlab::LDAP::Group.new(
            Net::LDAP::Entry.from_single_ldif_string(
              <<-EOS.strip_heredoc
                dn: cn=ldap_group1,ou=groups,dc=example,dc=com
                cn: ldap_group1
                description: LDAP Group 1
                memberuid: #{user1.username}
                objectclass: top
                objectclass: posixGroup
              EOS
            )
          )
        end
        let(:ldap_user) do
          Gitlab::LDAP::Person.new(
            Net::LDAP::Entry.from_single_ldif_string(
              "dn: uid=#{user1.username},ou=users,dc=example,dc=com"
            ),
            'ldapmain'
          )
        end

        before do
          allow(Gitlab::LDAP::Person)
            .to receive(:find_by_uid)
              .with(user1.username, any_args)
              .and_return(ldap_user)
        end

        it 'adds the user to the group' do
          expect { group_sync.sync_groups }
            .to change { group1.members.where(user_id: user1.id).any? }
              .from(false).to(true)
        end

        it 'expects Gitlab::LDAP::Person to be called' do
          expect(Gitlab::LDAP::Person).to receive(:find_by_uid)

          group_sync.sync_groups
        end

        it do
          expect { group_sync.sync_groups }
            .to change {
              user1.identities.find_by(
                provider: group_sync.provider,
                extern_uid: ldap_user.dn
              ).secondary_extern_uid
            }.from(nil).to(user1.username)
        end

        context 'when the uid is stored in the database' do
          let(:secondary_extern_uid) { user1.username }

          it 'expects Gitlab::LDAP::Person will not be called' do
            expect(Gitlab::LDAP::Person)
              .not_to receive(:find_by_uid)
                .with(user1.username, any_args)

            group_sync.sync_groups
          end
        end

        context 'when a DN for UID is requesting multiple times' do
          let(:secondary_extern_uid) { user1.username }

          before do
            # Group 1 link was created above. Create another here.
            group2.ldap_group_links.create(
              cn: ldap_group.cn,
              group_access: Gitlab::Access::DEVELOPER,
              provider: 'ldapmain'
            )
          end

          it 'expects the identity will be retrieved from the database once' do
            expect(Identity).to receive(:find_by)
              .with(
                provider: 'ldapmain',
                secondary_extern_uid: secondary_extern_uid
              ).once.and_call_original

            group_sync.sync_groups
          end

          it 'expects Gitlab::LDAP::Person will not be called' do
            expect(Gitlab::LDAP::Person)
              .not_to receive(:find_by_uid)
                .with(user1.username, any_args)

            group_sync.sync_groups
          end
        end
      end

      context 'with groupOfUniqueNames style LDAP group' do
        let(:ldap_group) do
          Gitlab::LDAP::Group.new(
            Net::LDAP::Entry.from_single_ldif_string(
              <<-EOS.strip_heredoc
                dn: cn=ldap_group1,ou=groups,dc=example,dc=com
                cn: ldap_group1
                description: LDAP Group 1
                uniquemember: uid=#{user1.username},ou=users,dc=example,dc=com
                objectclass: top
                objectclass: groupOfUniqueNames
              EOS
            )
          )
        end

        it 'adds the user to the group' do
          expect { group_sync.sync_groups }
            .to change { group1.members.where(user_id: user1.id).any? }
              .from(false).to(true)
        end
      end

      context 'with an empty LDAP group' do
        let(:ldap_group) do
          Gitlab::LDAP::Group.new(
            Net::LDAP::Entry.from_single_ldif_string(
              <<-EOS.strip_heredoc
                dn: cn=ldap_group1,ou=groups,dc=example,dc=com
                cn: ldap_group1
                description: LDAP Group 1
                objectclass: top
                objectclass: groupOfUniqueNames
              EOS
            )
          )
        end

        it 'does nothing, without failure' do
          expect { group_sync.sync_groups }
            .not_to change { group1.members.count }
        end
      end

      # See gitlab-ee#442 and comment in GroupSync#ensure_full_dns!
      context 'with uid=username member format' do
        let(:ldap_group) do
          Gitlab::LDAP::Group.new(
            Net::LDAP::Entry.from_single_ldif_string(
              <<-EOS.strip_heredoc
                dn: cn=ldap_group1,ou=groups,dc=example,dc=com
                cn: ldap_group1
                member: uid=#{user1.username}
                description: LDAP Group 1
                objectclass: top
                objectclass: groupOfUniqueNames
              EOS
            )
          )
        end
        let(:ldap_user) do
          Gitlab::LDAP::Person.new(
            Net::LDAP::Entry.from_single_ldif_string(
              "dn: uid=#{user1.username},ou=users,dc=example,dc=com"
            ),
            'ldapmain'
          )
        end

        before do
          allow(Gitlab::LDAP::Person)
            .to receive(:find_by_uid)
              .with(user1.username, any_args)
              .and_return(ldap_user)
        end

        it 'adds the user to the group' do
          expect { group_sync.sync_groups }
            .to change { group1.members.where(user_id: user1.id).any? }
              .from(false).to(true)
        end

        it 'expects Gitlab::LDAP::Person to be called' do
          expect(Gitlab::LDAP::Person).to receive(:find_by_uid)

          group_sync.sync_groups
        end

        it do
          expect { group_sync.sync_groups }
            .to change {
              user1.identities.find_by(
                provider: group_sync.provider,
                extern_uid: ldap_user.dn
              ).secondary_extern_uid
            }.from(nil).to(user1.username)
        end
      end
    end
  end

  describe '#sync_admin_users' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    let(:admin_group) do
      Net::LDAP::Entry.from_single_ldif_string(
        <<-EOS.strip_heredoc
          dn: cn=admin_group,ou=groups,dc=example,dc=com
          cn: admin_group
          description: Admin Group
          gidnumber: 42
          uniqueMember: uid=#{user2.username},ou=users,dc=example,dc=com
          objectclass: top
          objectclass: groupOfNames
        EOS
      )
    end

    before do
      user1.admin = true
      user1.save
      user3.admin = true
      user3.save

      allow_any_instance_of(Gitlab::LDAP::Group)
        .to receive(:adapter).and_return(adapter)
      allow(Gitlab::LDAP::Group)
        .to receive(:find_by_cn).with(admin_group.cn, any_args)
      allow(Gitlab::LDAP::Group)
        .to receive(:find_by_cn)
          .with('admin_group', kind_of(Gitlab::LDAP::Adapter))
          .and_return(Gitlab::LDAP::Group.new(admin_group))

      user1.identities.create(
        provider: 'ldapmain',
        extern_uid: "uid=#{user1.username},ou=users,dc=example,dc=com"
      )
      user2.identities.create(
        provider: 'ldapmain',
        extern_uid: "uid=#{user2.username},ou=users,dc=example,dc=com"
      )

      allow(group_sync).to receive_messages(admin_group: 'admin_group')
    end

    it 'adds new admin users' do
      expect { group_sync.sync_admin_users }
        .to change { User.admins.where(id: user2.id).any? }.from(false).to(true)
    end

    it 'removes users that are not in the LDAP group' do
      expect { group_sync.sync_admin_users }
        .to change { User.admins.where(id: user1.id).any? }.from(true).to(false)
    end

    it 'leaves admins that do not have the LDAP provider' do
      expect { group_sync.sync_admin_users }
        .not_to change { User.admins.where(id: user3.id).any? }
    end
  end
end
