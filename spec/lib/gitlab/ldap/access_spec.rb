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

        it 'blocks user in GitLab' do
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

        context 'when user cannot be found' do
          before do
            allow(Gitlab::LDAP::Person).to receive(:find_by_dn).and_return(nil)
          end

          it { is_expected.to be_falsey }

          it 'blocks user in GitLab' do
            access.allowed?
            expect(user).to be_blocked
            expect(user).to be_ldap_blocked
          end
        end

        context 'when user was previously ldap_blocked' do
          before do
            user.ldap_block
          end

          it 'unblocks the user if it exists' do
            access.allowed?
            expect(user).not_to be_blocked
          end
        end
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
end
