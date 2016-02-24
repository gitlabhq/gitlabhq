require 'spec_helper'

describe Gitlab::LDAP::Access, lib: true do
  let(:access) { Gitlab::LDAP::Access.new user }
  let(:user) { create(:omniauth_user) }

  describe '#allowed?' do
    subject { access.allowed? }

    context 'when the user cannot be found' do
      before do
        allow(Gitlab::LDAP::Person).to receive(:find_by_dn).and_return(nil)
      end

      it { is_expected.to be_falsey }

      it 'should block user in GitLab' do
        access.allowed?
        expect(user).to be_blocked
        expect(user).to be_ldap_blocked
      end
    end

    context 'when the user is found' do
      before do
        allow(Gitlab::LDAP::Person).to receive(:find_by_dn).and_return(:ldap_user)
      end

      context 'and the user is disabled via active directory' do
        before do
          allow(Gitlab::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(true)
        end

        it { is_expected.to be_falsey }

        it 'should block user in GitLab' do
          access.allowed?
          expect(user).to be_blocked
          expect(user).to be_ldap_blocked
        end
      end

      context 'and has no disabled flag in active directory' do
        before do
          allow(Gitlab::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(false)
        end

        it { is_expected.to be_truthy }

        context 'when auto-created users are blocked' do
          before do
            user.block
          end

          it 'does not unblock user in GitLab' do
            access.allowed?
            expect(user).to be_blocked
            expect(user).not_to be_ldap_blocked # this block is handled by omniauth not by our internal logic
          end
        end

        context 'when auto-created users are not blocked' do
          before do
            user.ldap_block
          end

          it 'should unblock user in GitLab' do
            access.allowed?
            expect(user).not_to be_blocked
          end
        end
      end

      context 'without ActiveDirectory enabled' do
        before do
          allow(Gitlab::LDAP::Config).to receive(:enabled?).and_return(true)
          allow_any_instance_of(Gitlab::LDAP::Config).to receive(:active_directory).and_return(false)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#update_user' do
    subject { access.update_user }
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
    end
    before do
      allow(access).to(
        receive_messages(
          ldap_user: Gitlab::LDAP::Person.new(entry, user.ldap_identity.provider)
        )
      )
    end

    it 'updates email address' do
      expect(access).to receive(:update_email).once

      subject
    end

    it 'syncs ssh keys if enabled by configuration' do
      allow(access).to receive_messages(group_base: '', sync_ssh_keys?: true)
      expect(access).to receive(:update_ssh_keys).once

      subject
    end

    it 'update_kerberos_identity' do
      allow(access).to receive_messages(import_kerberos_identities?: true)
      expect(access).to receive(:update_kerberos_identity).once

      subject
    end
  end

  describe '#update_permissions' do
    subject { access.update_permissions({}) }

    it 'does update group permissions with a group base configured' do
      allow(access).to receive_messages(group_base: 'my-group-base')
      expect(LdapGroupLinksWorker).to receive(:perform_async).with(user.id)

      subject
    end

    it 'does not update group permissions without a group base configured' do
      allow(access).to receive_messages(group_base: '')
      expect(LdapGroupLinksWorker).not_to receive(:perform_async)

      subject
    end

    it 'does update admin group permissions if admin group is configured' do
      allow(access).to receive_messages(admin_group: 'my-admin-group')
      expect(access).to receive(:update_admin_status)

      subject
    end

    it 'does not update admin status when admin group is not configured' do
      allow(access).to receive_messages(admin_group: '')
      expect(access).not_to receive(:update_admin_status)

      subject
    end

    context 'when synchronously updating group permissions' do
      subject { access.update_permissions(update_ldap_group_links_synchronously: true) }
      
      it 'updates group permissions directly' do
        allow(access).to receive_messages(group_base: 'my-group-base')
        expect(LdapGroupLinksWorker).not_to receive(:perform_async)
        expect(access).to receive(:update_ldap_group_links)
  
        subject
      end      
    end
  end

  describe :update_kerberos_identity do
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
    end

    before do
      allow(access).to receive_messages(ldap_user: Gitlab::LDAP::Person.new(entry, user.ldap_identity.provider))
    end

    it "should add a Kerberos identity if it is in Active Directory but not in GitLab" do
      allow_any_instance_of(Gitlab::LDAP::Person).to receive_messages(kerberos_principal: "mylogin@FOO.COM")

      expect{ access.update_kerberos_identity }.to change(user.identities.where(provider: :kerberos), :count).from(0).to(1)
      expect(user.identities.where(provider: "kerberos").last.extern_uid).to eq("mylogin@FOO.COM")
    end

    it "should update existing Kerberos identity in GitLab if Active Directory has a different one" do
      allow_any_instance_of(Gitlab::LDAP::Person).to receive_messages(kerberos_principal: "otherlogin@BAR.COM")
      user.identities.build(provider: "kerberos", extern_uid: "mylogin@FOO.COM").save

      expect{ access.update_kerberos_identity }.not_to change(user.identities.where(provider: "kerberos"), :count)
      expect(user.identities.where(provider: "kerberos").last.extern_uid).to eq("otherlogin@BAR.COM")
    end

    it "should not remove Kerberos identities from GitLab if they are none in the LDAP provider" do
      allow_any_instance_of(Gitlab::LDAP::Person).to receive_messages(kerberos_principal: nil)
      user.identities.build(provider: "kerberos", extern_uid: "otherlogin@BAR.COM").save

      expect{ access.update_kerberos_identity }.not_to change(user.identities.where(provider: "kerberos"), :count)
      expect(user.identities.where(provider: "kerberos").last.extern_uid).to eq("otherlogin@BAR.COM")
    end

    it "should not modify identities in GitLab if they are no kerberos principal in the LDAP provider" do
      allow_any_instance_of(Gitlab::LDAP::Person).to receive_messages(kerberos_principal: nil)

      expect{ access.update_kerberos_identity }.not_to change(user.identities, :count)
    end
  end

  describe :update_ssh_keys do
    let(:ssh_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj" }
    let(:ssh_key_attribute_name) { 'altSecurityIdentities' }
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: SSHKey:#{ssh_key}\n#{ssh_key_attribute_name}: KerberosKey:bogus")
    end

    before do
      allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(sync_ssh_keys: ssh_key_attribute_name)
      allow(access).to receive_messages(sync_ssh_keys?: true)
    end

    it "should add a SSH key if it is in LDAP but not in gitlab" do
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

      expect{ access.update_ssh_keys }.to change(user.keys, :count).from(0).to(1)
    end

    it "should add a SSH key and give it a proper name" do
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

      access.update_ssh_keys
      expect(user.keys.last.title).to match(/LDAP/)
      expect(user.keys.last.title).to match(/#{access.ldap_config.sync_ssh_keys}/)
    end

    it "should not add a SSH key if it is invalid" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: I am not a valid key")
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

      expect{ access.update_ssh_keys }.not_to change(user.keys, :count)
    end

    context 'user has at least one LDAPKey' do
      before { user.keys.ldap.create key: ssh_key, title: 'to be removed' }

      it "should remove a SSH key if it is no longer in LDAP" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}:\n")
        allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

        expect{ access.update_ssh_keys }.to change(user.keys, :count).from(1).to(0)
      end

      it "should remove a SSH key if the ldap attribute was removed" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
        allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:user) { Gitlab::LDAP::Person.new(entry, 'ldapmain') }

        expect{ access.update_ssh_keys }.to change(user.keys, :count).from(1).to(0)
      end
    end
  end

  describe :update_user_email do
    let(:entry) { Net::LDAP::Entry.new }

    before do
      allow(access).to receive_messages(ldap_user: Gitlab::LDAP::Person.new(entry, user.ldap_identity.provider))
    end

    it "should not update email if email attribute is not set" do
      expect{ access.update_email }.not_to change(user, :email)
    end

    it "should not update the email if the user has the same email in GitLab and in LDAP" do
      entry['mail'] = [user.email]
      expect{ access.update_email }.not_to change(user, :email)
    end

    it "should not update the email if the user has the same email GitLab and in LDAP, but with upper case in LDAP" do
      entry['mail'] = [user.email.upcase]
      expect{ access.update_email }.not_to change(user, :email)
    end

    it "should update the email if the user email is different" do
      entry['mail'] = ["new_email@example.com"]
      expect{ access.update_email }.to change(user, :email)
    end
  end


  describe :update_admin_status do
    before do
      allow(access).to receive_messages(admin_group: "GLAdmins")
      ldap_user_entry = Net::LDAP::Entry.new
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:user) { Gitlab::LDAP::Person.new(ldap_user_entry, user.ldap_identity.provider) }
      allow_any_instance_of(Gitlab::LDAP::Person).to receive(:uid) { 'admin2' }
    end

    it "should give admin privileges to an User" do
      admin_group = Net::LDAP::Entry.from_single_ldif_string(
        %Q{dn: cn=#{access.admin_group},ou=groups,dc=bar,dc=com
cn: #{access.admin_group}
description: GitLab admins
gidnumber: 42
memberuid: admin1
memberuid: admin2
memberuid: admin3
objectclass: top
objectclass: posixGroup
      })
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:group) { Gitlab::LDAP::Group.new(admin_group) }

      expect{ access.update_admin_status }.to change(user, :admin?).to(true)
    end

    it "should remove admin privileges from an User" do
      user.update_attribute(:admin, true)
      admin_group = Net::LDAP::Entry.from_single_ldif_string(
        %Q{dn: cn=#{access.admin_group},ou=groups,dc=bar,dc=com
cn: #{access.admin_group}
description: GitLab admins
gidnumber: 42
memberuid: admin1
memberuid: admin3
objectclass: top
objectclass: posixGroup
      })
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:group) { Gitlab::LDAP::Group.new(admin_group) }
      expect{ access.update_admin_status }.to change(user, :admin?).to(false)
    end
  end


  describe :update_ldap_group_links do
    let(:cns_with_access) { %w(ldap-group1 ldap-group2) }
    let(:gitlab_group_1) { create :group }
    let(:gitlab_group_2) { create :group }

    before do
      allow(access).to receive_messages(cns_with_access: cns_with_access)
    end

    context "non existing access for group-1, allowed via ldap-group1 as MASTER" do
      before do
        gitlab_group_1.ldap_group_links.create({
          cn: 'ldap-group1', group_access: Gitlab::Access::MASTER, provider: 'ldapmain' })
      end

      it "gives the user master access for group 1" do
        access.update_ldap_group_links
        expect( gitlab_group_1.has_master?(user) ).to be_truthy
      end

      it "doesn't send a notification email" do
        expect { access.update_ldap_group_links }.not_to \
          change { ActionMailer::Base.deliveries }
      end
    end

    context "existing access as guest for group-1, allowed via ldap-group1 as DEVELOPER" do
      before do
        gitlab_group_1.group_members.guests.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create({
          cn: 'ldap-group1', group_access: Gitlab::Access::MASTER, provider: 'ldapmain' })
      end

      it "upgrades the users access to master for group 1" do
        expect { access.update_ldap_group_links }.to \
          change{ gitlab_group_1.has_master?(user) }.from(false).to(true)
      end

      it "doesn't send a notification email" do
        expect { access.update_ldap_group_links }.not_to \
          change { ActionMailer::Base.deliveries }
      end
    end

    context 'existing access as MASTER for group-1, allowed via ldap-group1 as DEVELOPER' do
      before do
        gitlab_group_1.group_members.masters.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create({
          cn: 'ldap-group1', group_access: Gitlab::Access::DEVELOPER, provider: 'ldapmain' })
      end

      it 'downgrades the users access' do
        expect { access.update_ldap_group_links }.to \
          change{ gitlab_group_1.has_master?(user) }.from(true).to(false)
      end

      it 'does not send a notification email' do
        expect { access.update_ldap_group_links }.not_to \
          change { ActionMailer::Base.deliveries }
      end
    end

    context "existing access as master for group-1, not allowed" do
      before do
        gitlab_group_1.group_members.masters.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create(cn: 'ldap-group1', group_access: Gitlab::Access::MASTER, provider: 'ldapmain')
        allow(access).to receive_messages(cns_with_access: ['ldap-group2'])
      end

      it "removes user from gitlab_group_1" do
        expect { access.update_ldap_group_links }.to \
          change{ gitlab_group_1.members.where(user_id: user).any? }.from(true).to(false)
      end
    end

    context "existing access as owner for group-1 with no other owner, not allowed" do
      before do
        gitlab_group_1.group_members.owners.create(user_id: user.id)
        gitlab_group_1.ldap_group_links.create(cn: 'ldap-group1', group_access: Gitlab::Access::OWNER, provider: 'ldapmain')
        allow(access).to receive_messages(cns_with_access: ['ldap-group2'])
      end

      it "does not remove the user from gitlab_group_1 since it's the last owner" do
        expect { access.update_ldap_group_links }.not_to \
          change{ gitlab_group_1.has_owner?(user) }
      end
    end

    context "existing access as owner for group-1 while other owners present, not allowed" do
      before do
        owner2 = create(:user) # a 2nd owner
        gitlab_group_1.group_members.owners.create([{ user_id: user.id }, { user_id: owner2.id }])
        gitlab_group_1.ldap_group_links.create(cn: 'ldap-group1', group_access: Gitlab::Access::OWNER, provider: 'ldapmain')
        allow(access).to receive_messages(cns_with_access: ['ldap-group2'])
      end

      it "removes user from gitlab_group_1" do
        expect { access.update_ldap_group_links }.to \
          change{ gitlab_group_1.members.where(user_id: user).any? }.from(true).to(false)
      end
    end
  end

  describe 'ldap_groups' do
    let(:ldap_group_1) do
      Net::LDAP::Entry.from_single_ldif_string(
        %Q{dn: cn=#{access.ldap_config.admin_group},ou=groups,dc=bar,dc=com
cn: #{access.ldap_config.admin_group}
description: GitLab group 1
gidnumber: 42
memberuid: user1
memberuid: user2
objectclass: top
objectclass: posixGroup
      })
    end

    it "returns an interator of LDAP Groups" do
      ::LdapGroupLink.create({
        cn: 'example', group_access: Gitlab::Access::DEVELOPER, group_id: 42, provider: 'ldapmain' })
      allow_any_instance_of(Gitlab::LDAP::Adapter).to receive(:group) { Gitlab::LDAP::Group.new(ldap_group_1) }

      expect(access.ldap_groups.first).to be_a Gitlab::LDAP::Group
    end

    it "only returns found ldap groups" do
      ::LdapGroupLink.create cn: 'example', group_access: Gitlab::Access::DEVELOPER, group_id: 42
      allow(Gitlab::LDAP::Group).to receive_messages(find_by_cn: nil) # group not found

      expect(access.ldap_groups).to be_empty
    end
  end

  describe :cns_with_access do
    let(:ldap_group_response_1) do
      Net::LDAP::Entry.from_single_ldif_string(
        %Q{dn: cn=group1,ou=groups,dc=bar,dc=com
cn: group1
description: GitLab group 1
gidnumber: 21
uniquemember: #{ldap_user.dn.downcase}
uniquemember: uid=user2,ou=people,dc=example
objectclass: top
objectclass: posixGroup
      })
    end

    let(:ldap_group_response_2) do
      Net::LDAP::Entry.from_single_ldif_string(
        %Q{dn: cn=group2,ou=groups,dc=bar,dc=com
cn: group2
description: GitLab group 2
gidnumber: 42
memberuid: user3
memberuid: user4
objectclass: top
objectclass: posixGroup
      })
    end

    let(:ldap_groups) do
      [
        Gitlab::LDAP::Group.new(ldap_group_response_1),
        Gitlab::LDAP::Group.new(ldap_group_response_2)
      ]
    end

    before do
      allow(ldap_user).to receive(:dn) { 'uid=user1,ou=People,dc=example' }
      allow(access).to receive_messages(ldap_groups: ldap_groups)
    end

    context 'when the LDAP user exists' do
      let(:ldap_user) { Gitlab::LDAP::Person.new(Net::LDAP::Entry.new, user.ldap_identity.provider) }

      before do
        allow(access).to receive_messages(ldap_user: ldap_user)
        allow(ldap_user).to receive(:uid) { 'user1' }
      end

      it 'only returns ldap cns to which the user has access' do
        expect(access.cns_with_access).to eq(['group1'])
      end
    end

    context 'when the LADP user does not exist' do
      let(:ldap_user) { nil }
      before do
        allow(access).to receive_messages(ldap_user: ldap_user)
      end

      it 'returns an empty array' do
        expect(access.cns_with_access).to eq([])
      end
    end
  end
end
