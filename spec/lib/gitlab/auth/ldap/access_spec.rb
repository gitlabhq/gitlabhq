require 'spec_helper'

describe Gitlab::Auth::LDAP::Access do
  include LdapHelpers

  let(:access) { described_class.new user }
  let(:user) { create(:omniauth_user) }

  describe '.allowed?' do
    it 'updates the users `last_credential_check_at' do
      allow(access).to receive(:update_user)
      expect(access).to receive(:allowed?) { true }
      expect(described_class).to receive(:open).and_yield(access)

      expect { described_class.allowed?(user) }
        .to change { user.last_credential_check_at }
    end
  end

  describe '#find_ldap_user' do
    it 'finds a user by dn first' do
      expect(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(:ldap_user)

      access.find_ldap_user
    end

    it 'finds a user by email if the email came from LDAP' do
      expect(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(nil)
      expect(Gitlab::Auth::LDAP::Person).to receive(:find_by_email)

      access.find_ldap_user
    end
  end

  describe '#allowed?' do
    subject { access.allowed? }

    context 'when the user cannot be found' do
      before do
        allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(nil)
        allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_email).and_return(nil)
      end

      it { is_expected.to be_falsey }

      it 'blocks user in GitLab' do
        expect(access).to receive(:block_user).with(user, 'does not exist anymore')

        access.allowed?
      end

      context 'when looking for a user by email' do
        let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

        it { is_expected.to be_falsey }
      end
    end

    context 'when the user is found' do
      let(:ldap_user) { Gitlab::Auth::LDAP::Person.new(Net::LDAP::Entry.new, 'ldapmain') }

      before do
        allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(ldap_user)
      end

      context 'and the user is disabled via active directory' do
        before do
          allow(Gitlab::Auth::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(true)
        end

        it { is_expected.to be_falsey }

        it 'blocks user in GitLab' do
          expect(access).to receive(:block_user).with(user, 'is disabled in Active Directory')

          access.allowed?
        end
      end

      context 'and has no disabled flag in active directory' do
        before do
          allow(Gitlab::Auth::LDAP::Person).to receive(:disabled_via_active_directory?).and_return(false)
        end

        it { is_expected.to be_truthy }

        context 'when auto-created users are blocked' do
          before do
            user.block
          end

          it 'does not unblock user in GitLab' do
            expect(access).not_to receive(:unblock_user)

            access.allowed?

            expect(user).to be_blocked
            expect(user).not_to be_ldap_blocked # this block is handled by omniauth not by our internal logic
          end
        end

        context 'when auto-created users are not blocked' do
          before do
            user.ldap_block
          end

          it 'unblocks user in GitLab' do
            expect(access).to receive(:unblock_user).with(user, 'is not disabled anymore')

            access.allowed?
          end
        end
      end

      context 'without ActiveDirectory enabled' do
        before do
          allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
          allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive(:active_directory).and_return(false)
        end

        it { is_expected.to be_truthy }

        context 'when user cannot be found' do
          before do
            allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(nil)
            allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_email).and_return(nil)
          end

          it { is_expected.to be_falsey }

          it 'blocks user in GitLab' do
            expect(access).to receive(:block_user).with(user, 'does not exist anymore')

            access.allowed?
          end
        end

        context 'when user was previously ldap_blocked' do
          before do
            user.ldap_block
          end

          it 'unblocks the user if it exists' do
            expect(access).to receive(:unblock_user).with(user, 'is available again')

            access.allowed?
          end
        end

        context 'when user was previously ldap_blocked' do
          before do
            user.ldap_block
          end

          it 'unblocks the user if it exists' do
            expect(access).to receive(:unblock_user).with(user, 'is available again')

            access.allowed?
          end
        end
      end
    end

    context 'when the connection fails' do
      before do
        raise_ldap_connection_error
      end

      it 'does not block the user' do
        access.allowed?

        expect(user.ldap_blocked?).to be_falsey
      end

      it 'denies access' do
        expect(access.allowed?).to be_falsey
      end
    end

    context 'when the connection fails' do
      before do
        raise_ldap_connection_error
      end

      it 'does not block the user' do
        access.allowed?

        expect(user.ldap_blocked?).to be_falsey
      end

      it 'denies access' do
        expect(access.allowed?).to be_falsey
      end
    end
  end

  describe '#block_user' do
    before do
      user.activate
      allow(Gitlab::AppLogger).to receive(:info)

      access.block_user user, 'reason'
    end

    it 'blocks the user' do
      expect(user).to be_blocked
      expect(user).to be_ldap_blocked
    end

    it 'logs the reason' do
      expect(Gitlab::AppLogger).to have_received(:info).with(
        "LDAP account \"123456\" reason, " \
        "blocking Gitlab user \"#{user.name}\" (#{user.email})"
      )
    end
  end

  describe '#unblock_user' do
    before do
      user.ldap_block
      allow(Gitlab::AppLogger).to receive(:info)

      access.unblock_user user, 'reason'
    end

    it 'activates the user' do
      expect(user).not_to be_blocked
      expect(user).not_to be_ldap_blocked
    end

    it 'logs the reason' do
      Gitlab::AppLogger.info(
        "LDAP account \"123456\" reason, " \
        "unblocking Gitlab user \"#{user.name}\" (#{user.email})"
      )
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
          ldap_user: Gitlab::Auth::LDAP::Person.new(entry, user.ldap_identity.provider)
        )
      )
    end

    it 'updates email address' do
      expect(access).to receive(:update_email).once

      subject
    end

    it 'updates the group memberships' do
      expect(access).to receive(:update_memberships).once

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

    it 'updates the ldap identity' do
      expect(access).to receive(:update_identity)

      subject
    end
  end

  describe '#update_kerberos_identity' do
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
    end

    before do
      allow(access).to receive_messages(ldap_user: Gitlab::Auth::LDAP::Person.new(entry, user.ldap_identity.provider))
    end

    it "adds a Kerberos identity if it is in Active Directory but not in GitLab" do
      allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: "mylogin@FOO.COM")

      expect { access.update_kerberos_identity }.to change(user.identities.where(provider: :kerberos), :count).from(0).to(1)
      expect(user.identities.where(provider: "kerberos").last.extern_uid).to eq("mylogin@FOO.COM")
    end

    it "updates existing Kerberos identity in GitLab if Active Directory has a different one" do
      allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: "otherlogin@BAR.COM")
      user.identities.build(provider: "kerberos", extern_uid: "mylogin@FOO.COM").save

      expect { access.update_kerberos_identity }.not_to change(user.identities.where(provider: "kerberos"), :count)
      expect(user.identities.where(provider: "kerberos").last.extern_uid).to eq("otherlogin@BAR.COM")
    end

    it "does not remove Kerberos identities from GitLab if they are none in the LDAP provider" do
      allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: nil)
      user.identities.build(provider: "kerberos", extern_uid: "otherlogin@BAR.COM").save

      expect { access.update_kerberos_identity }.not_to change(user.identities.where(provider: "kerberos"), :count)
      expect(user.identities.where(provider: "kerberos").last.extern_uid).to eq("otherlogin@BAR.COM")
    end

    it "does not modify identities in GitLab if they are no kerberos principal in the LDAP provider" do
      allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: nil)

      expect { access.update_kerberos_identity }.not_to change(user.identities, :count)
    end
  end

  describe '#update_ssh_keys' do
    let(:ssh_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj" }
    let(:ssh_key_attribute_name) { 'altSecurityIdentities' }
    let(:entry) do
      Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: SSHKey:#{ssh_key}\n#{ssh_key_attribute_name}: KerberosKey:bogus")
    end

    before do
      allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(sync_ssh_keys: ssh_key_attribute_name)
      allow(access).to receive_messages(sync_ssh_keys?: true)
    end

    it "adds a SSH key if it is in LDAP but not in gitlab" do
      allow_any_instance_of(Gitlab::Auth::LDAP::Adapter).to receive(:user) { Gitlab::Auth::LDAP::Person.new(entry, 'ldapmain') }

      expect { access.update_ssh_keys }.to change(user.keys, :count).from(0).to(1)
    end

    it "adds a SSH key and give it a proper name" do
      allow_any_instance_of(Gitlab::Auth::LDAP::Adapter).to receive(:user) { Gitlab::Auth::LDAP::Person.new(entry, 'ldapmain') }

      access.update_ssh_keys
      expect(user.keys.last.title).to match(/LDAP/)
      expect(user.keys.last.title).to match(/#{access.ldap_config.sync_ssh_keys}/)
    end

    it "does not add a SSH key if it is invalid" do
      entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: I am not a valid key")
      allow_any_instance_of(Gitlab::Auth::LDAP::Adapter).to receive(:user) { Gitlab::Auth::LDAP::Person.new(entry, 'ldapmain') }

      expect { access.update_ssh_keys }.not_to change(user.keys, :count)
    end

    context 'user has at least one LDAPKey' do
      before do
        user.keys.ldap.create key: ssh_key, title: 'to be removed'
      end

      it "removes a SSH key if it is no longer in LDAP" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}:\n")
        allow_any_instance_of(Gitlab::Auth::LDAP::Adapter).to receive(:user) { Gitlab::Auth::LDAP::Person.new(entry, 'ldapmain') }

        expect { access.update_ssh_keys }.to change(user.keys, :count).from(1).to(0)
      end

      it "removes a SSH key if the ldap attribute was removed" do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
        allow_any_instance_of(Gitlab::Auth::LDAP::Adapter).to receive(:user) { Gitlab::Auth::LDAP::Person.new(entry, 'ldapmain') }

        expect { access.update_ssh_keys }.to change(user.keys, :count).from(1).to(0)
      end
    end
  end

  describe '#update_user_email' do
    let(:entry) { Net::LDAP::Entry.new }

    before do
      allow(access).to receive_messages(ldap_user: Gitlab::Auth::LDAP::Person.new(entry, user.ldap_identity.provider))
    end

    it "does not update email if email attribute is not set" do
      expect { access.update_email }.not_to change(user, :email)
    end

    it "does not update the email if the user has the same email in GitLab and in LDAP" do
      entry['mail'] = [user.email]
      expect { access.update_email }.not_to change(user, :email)
    end

    it "does not update the email if the user has the same email GitLab and in LDAP, but with upper case in LDAP" do
      entry['mail'] = [user.email.upcase]
      expect { access.update_email }.not_to change(user, :email)
    end

    it "updates the email if the user email is different" do
      entry['mail'] = ["new_email@example.com"]
      expect { access.update_email }.to change(user, :email)
    end
  end

  describe '#update_memberships' do
    let(:provider) { user.ldap_identity.provider }
    let(:entry) { ldap_user_entry(user.ldap_identity.extern_uid) }

    let(:person_with_memberof) do
      entry['memberof'] = ['CN=Group1,CN=Users,DC=The dc,DC=com',
                           'CN=Group2,CN=Builtin,DC=The dc,DC=com']
      Gitlab::Auth::LDAP::Person.new(entry, provider)
    end

    it 'triggers a sync for all groups found in `memberof`' do
      group_link_1 = create(:ldap_group_link, cn: 'Group1', provider: provider)
      group_link_2 = create(:ldap_group_link, cn: 'Group2', provider: provider)
      group_ids = [group_link_1, group_link_2].map(&:group_id)

      allow(access).to receive(:ldap_user).and_return(person_with_memberof)

      expect(LdapGroupSyncWorker).to receive(:perform_async)
        .with(a_collection_containing_exactly(*group_ids), provider)

      access.update_memberships
    end

    it "doesn't continue when there is no `memberOf` param" do
      allow(access).to receive(:ldap_user)
                         .and_return(Gitlab::Auth::LDAP::Person.new(entry, provider))

      expect(LdapGroupLink).not_to receive(:where)
      expect(LdapGroupSyncWorker).not_to receive(:perform_async)

      access.update_memberships
    end

    it "doesn't trigger a sync when there are no links for the provider" do
      _another_provider = create(:ldap_group_link,
                                 cn: 'Group1',
                                 provider: 'not-this-ldap')

      allow(access).to receive(:ldap_user).and_return(person_with_memberof)

      expect(LdapGroupSyncWorker).not_to receive(:perform_async)

      access.update_memberships
    end
  end

  describe '#update_identity' do
    it 'updates the external UID if it changed in the entry' do
      entry = ldap_user_entry('another uid')
      provider = user.ldap_identity.provider
      person = Gitlab::Auth::LDAP::Person.new(entry, provider)

      allow(access).to receive(:ldap_user).and_return(person)

      access.update_identity

      expect(user.ldap_identity.reload.extern_uid)
        .to eq('uid=another uid,ou=users,dc=example,dc=com')
    end
  end
end
