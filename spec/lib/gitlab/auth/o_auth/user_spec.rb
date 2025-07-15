# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::User, :aggregate_failures, feature_category: :system_access do
  include LdapHelpers

  let_it_be(:organization) { create(:organization) }
  let(:oauth_user) { described_class.new(auth_hash, organization_id: organization.id) }
  let(:oauth_user_2) { described_class.new(auth_hash_2, organization_id: organization.id) }
  let(:gl_user) { oauth_user.gl_user }
  let(:gl_user_2) { oauth_user_2.gl_user }
  let(:uid) { 'my-uid' }
  let(:uid_2) { 'my-uid-2' }
  let(:dn) { 'uid=user1,ou=people,dc=example' }
  let(:provider) { 'my-provider' }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash) }
  let(:auth_hash_2) { OmniAuth::AuthHash.new(uid: uid_2, provider: provider, info: info_hash) }
  let(:info_hash) do
    {
      nickname: '-john+gitlab-ETC%.git@gmail.com',
      name: 'John',
      email: 'john@mail.com',
      address: {
        locality: 'locality',
        country: 'country'
      },
      organization: 'GitLab',
      job_title: 'Software Engineer'
    }
  end

  let(:ldap_user) { Gitlab::Auth::Ldap::Person.new(Net::LDAP::Entry.new, 'ldapmain') }
  let(:ldap_user_2) { Gitlab::Auth::Ldap::Person.new(Net::LDAP::Entry.new, 'ldapmain') }

  describe '.find_by_uid_and_provider' do
    let(:provider) { 'provider' }
    let(:uid) { 'uid' }
    let(:user) { create(:user) }
    let!(:identity) { create(:identity, provider: provider, extern_uid: uid, user: user) }

    context 'when user exists for given uid and provider' do
      it 'returns the user for given uid and provider' do
        expect(described_class.find_by_uid_and_provider(uid, provider)).to eq user
      end

      context "when user's identity with untrusted extern_uid" do
        before do
          identity.update!(trusted_extern_uid: false)
        end

        it 'raises Gitlab::Auth::OAuth::User::IdentityWithUntrustedExternUidError' do
          expect { described_class.find_by_uid_and_provider(uid, provider) }
            .to raise_error(Gitlab::Auth::OAuth::User::IdentityWithUntrustedExternUidError)
        end
      end
    end

    context 'when user does not exist for given uid and provider' do
      it 'returns nil' do
        expect(described_class.find_by_uid_and_provider('unknown-uid', provider)).to eq nil
      end
    end

    context 'when identity exists for given uid and provider but is not tied to a user' do
      before do
        identity.update!(user: nil)
      end

      it 'returns nil' do
        expect(described_class.find_by_uid_and_provider(uid, provider)).to eq nil
      end
    end

    context 'for LDAP' do
      let(:dn) { 'CN=John Åström, CN=Users, DC=Example, DC=com' }

      it 'retrieves the correct user' do
        special_info = {
          name: 'John Åström',
          email: 'john@example.com',
          nickname: 'jastrom'
        }
        special_hash = OmniAuth::AuthHash.new(uid: dn, provider: 'ldapmain', info: special_info)
        special_chars_user = described_class.new(special_hash, organization_id: organization.id)
        user = special_chars_user.save

        expect(described_class.find_by_uid_and_provider(dn, 'ldapmain')).to eq user
      end
    end
  end

  describe '#persisted?' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    it "finds an existing user based on uid and provider (facebook)" do
      expect(oauth_user.persisted?).to be_truthy
    end

    it 'returns false if user is not found in database' do
      allow(auth_hash).to receive(:uid).and_return('non-existing')
      expect(oauth_user.persisted?).to be_falsey
    end
  end

  def stub_omniauth_config(messages)
    allow(Gitlab.config.omniauth).to receive_messages(messages)
  end

  describe '#save' do
    let(:provider) { 'twitter' }

    describe 'when account exists on server' do
      it 'does not mark the user as external' do
        create(:omniauth_user, extern_uid: 'my-uid', provider: provider)
        stub_omniauth_config(allow_single_sign_on: [provider], external_providers: [provider])

        oauth_user.save # rubocop:disable Rails/SaveBang

        expect(gl_user).to be_valid
        expect(gl_user.external).to be_falsey
      end
    end

    describe 'signup' do
      context 'when signup is disabled' do
        before do
          stub_application_setting signup_enabled: false
          stub_omniauth_config(allow_single_sign_on: [provider])
        end

        it 'creates the user' do
          oauth_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_persisted
        end

        it 'does not repeat the default user password' do
          oauth_user.save # rubocop:disable Rails/SaveBang
          oauth_user_2.save # rubocop:disable Rails/SaveBang

          expect(gl_user.password).not_to eq(gl_user_2.password)
        end

        it 'has the password length within specified range' do
          oauth_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user.password.length).to be_between(Devise.password_length.min, Devise.password_length.max)
        end
      end

      context 'when user confirmation email is enabled' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'hard')
        end

        it 'creates and confirms the user anyway' do
          stub_omniauth_config(allow_single_sign_on: [provider])

          oauth_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_persisted
          expect(gl_user).to be_confirmed
        end
      end

      context 'when the current minimum password length is different from the default minimum password length' do
        before do
          stub_application_setting minimum_password_length: 21
        end

        it 'creates the user' do
          stub_omniauth_config(allow_single_sign_on: [provider])

          oauth_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_persisted
        end
      end

      context 'when email address is too long' do
        def long_email_local_part
          "reallylongemail" * 300
        end

        let(:info_hash) do
          {
            email: "#{long_email_local_part}@example.com"
          }
        end

        it 'generates an empty username and produces an error' do
          oauth_user.save # rubocop:disable Rails/SaveBang -- Not an ActiveRecord object

          expect(gl_user.username).to eq("blank")
          expect(gl_user.errors.full_messages.to_sentence)
            .to eq("Identity provider email " + _("must be 254 characters or less."))
          expect(oauth_user).not_to be_valid
          expect(oauth_user).not_to be_valid_sign_in
        end
      end

      it 'marks user as having password_automatically_set' do
        stub_omniauth_config(allow_single_sign_on: [provider], external_providers: [provider])

        oauth_user.save # rubocop:disable Rails/SaveBang

        expect(gl_user).to be_persisted
        expect(gl_user).to be_password_automatically_set
      end

      shared_examples 'to verify compliance with allow_single_sign_on' do
        context 'provider is marked as external' do
          it 'marks user as external' do
            stub_omniauth_config(allow_single_sign_on: [provider], external_providers: [provider])
            oauth_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user.external).to be_truthy
          end
        end

        context 'provider was external, now has been removed' do
          it 'does not mark external user as internal' do
            create(:omniauth_user, extern_uid: 'my-uid', provider: provider, external: true)
            stub_omniauth_config(allow_single_sign_on: [provider], external_providers: ['facebook'])
            oauth_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user.external).to be_truthy
          end
        end

        context 'provider is not external' do
          context 'when adding a new OAuth identity' do
            it 'does not promote an external user to internal' do
              user = create(:user, email: 'john@mail.com', external: true)
              user.identities.create!(provider: provider, extern_uid: uid)

              oauth_user.save # rubocop:disable Rails/SaveBang
              expect(gl_user).to be_valid
              expect(gl_user.external).to be_truthy
            end
          end
        end

        context 'with new allow_single_sign_on enabled syntax' do
          before do
            stub_omniauth_config(allow_single_sign_on: [provider])
          end

          it "creates a user from Omniauth" do
            oauth_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            identity = gl_user.identities.first
            expect(identity.extern_uid).to eql uid
            expect(identity.provider).to eql provider
          end
        end

        context "with old allow_single_sign_on enabled syntax" do
          before do
            stub_omniauth_config(allow_single_sign_on: true)
          end

          it "creates a user from Omniauth" do
            oauth_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            identity = gl_user.identities.first
            expect(identity.extern_uid).to eql uid
            expect(identity.provider).to eql provider
          end
        end

        context 'with new allow_single_sign_on disabled syntax' do
          before do
            stub_omniauth_config(allow_single_sign_on: [])
          end

          it 'throws an error' do
            expect { oauth_user.save }.to raise_error StandardError # rubocop:disable Rails/SaveBang
          end
        end

        context 'with old allow_single_sign_on disabled (Default)' do
          before do
            stub_omniauth_config(allow_single_sign_on: false)
          end

          it 'throws an error' do
            expect { oauth_user.save }.to raise_error StandardError # rubocop:disable Rails/SaveBang
          end
        end
      end

      context "with auto_link_user disabled (default)" do
        before do
          stub_omniauth_config(auto_link_user: false)
        end

        include_examples "to verify compliance with allow_single_sign_on"
      end

      context "with auto_link_user enabled for a different provider" do
        before do
          stub_omniauth_config(auto_link_user: ['saml'])
        end

        context "and a current GitLab user with a matching email" do
          let!(:existing_user) { create(:user, email: 'john@mail.com', username: 'john') }

          it "adds the OmniAuth identity to the GitLab user account" do
            oauth_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).not_to be_valid
          end
        end

        context "and no current GitLab user with a matching email" do
          include_examples "to verify compliance with allow_single_sign_on"
        end
      end

      context "with auto_link_user enabled for the correct provider" do
        before do
          stub_omniauth_config(auto_link_user: ['twitter'])
        end

        context "and a current GitLab user with a matching email" do
          let!(:existing_user) { create(:user, email: 'john@mail.com', username: 'john') }

          it "adds the OmniAuth identity to the GitLab user account" do
            oauth_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user.username).to eql 'john'
            expect(gl_user.email).to eql 'john@mail.com'
            expect(gl_user.identities.length).to be 1
            identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
            expect(identities_as_hash).to match_array(
              [
                { provider: 'twitter', extern_uid: uid }
              ]
            )
          end
        end

        context "and no current GitLab user with a matching email" do
          include_examples "to verify compliance with allow_single_sign_on"
        end
      end

      context "with auto_link_user enabled for all providers" do
        before do
          stub_omniauth_config(auto_link_user: true)
        end

        context "and a current GitLab user with a matching email" do
          let!(:existing_user) { create(:user, email: 'john@mail.com', username: 'john') }

          it "adds the OmniAuth identity to the GitLab user account" do
            oauth_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            expect(gl_user.username).to eql 'john'
            expect(gl_user.email).to eql 'john@mail.com'
            expect(gl_user.identities.length).to be 1
            identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
            expect(identities_as_hash).to match_array(
              [
                { provider: 'twitter', extern_uid: uid }
              ]
            )
          end
        end

        context "and no current GitLab user with a matching email" do
          include_examples "to verify compliance with allow_single_sign_on"
        end
      end

      context "with auto_link_ldap_user disabled (default)" do
        before do
          stub_omniauth_config(auto_link_ldap_user: false)
        end

        include_examples "to verify compliance with allow_single_sign_on"

        context 'and other providers' do
          context 'when sync_name is disabled' do
            before do
              stub_ldap_config(sync_name: false)
            end

            let!(:existing_user) { create(:omniauth_user, name: 'John Swift', email: 'john@example.com', extern_uid: dn, provider: 'twitter', username: 'john') }

            it "updates the gl_user name" do
              oauth_user.save # rubocop:disable Rails/SaveBang

              expect(gl_user).to be_valid
              expect(gl_user.name).to eql 'John'
            end
          end

          context 'when sync_name is enabled' do
            before do
              stub_ldap_config(sync_name: true)
            end

            let!(:existing_user) { create(:omniauth_user, name: 'John Swift', email: 'john@example.com', extern_uid: dn, provider: 'twitter', username: 'john') }

            it "updates the gl_user name" do
              oauth_user.save # rubocop:disable Rails/SaveBang

              expect(gl_user).to be_valid
              expect(gl_user.name).to eql 'John'
            end
          end
        end
      end

      context "with auto_link_ldap_user enabled" do
        before do
          stub_omniauth_config(auto_link_ldap_user: true)
        end

        context "and no LDAP provider defined" do
          before do
            allow(Gitlab::Auth::Ldap::Config).to receive(:providers).at_least(:once).and_return([])
          end

          include_examples "to verify compliance with allow_single_sign_on"
        end

        context "and at least one LDAP provider is defined" do
          before do
            stub_ldap_config(providers: %w[ldapmain])
          end

          context "and a corresponding LDAP person" do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { uid }
              allow(ldap_user).to receive(:name) { 'John Doe' }
              allow(ldap_user).to receive(:email) { ['johndoe@example.com', 'john2@example.com'] }
              allow(ldap_user).to receive(:dn) { dn }

              allow(ldap_user_2).to receive(:uid) { uid_2 }
              allow(ldap_user_2).to receive(:username) { uid_2 }
              allow(ldap_user_2).to receive(:name) { 'Beck Potter' }
              allow(ldap_user_2).to receive(:email) { ['beckpotter@example.com', 'beck2@example.com'] }
              allow(ldap_user_2).to receive(:dn) { dn }
            end

            context "and no account for the LDAP user" do
              context 'when the LDAP user is found by UID' do
                before do
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)

                  oauth_user.save # rubocop:disable Rails/SaveBang
                end

                it 'does not repeat the default user password' do
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user_2)

                  oauth_user_2.save # rubocop:disable Rails/SaveBang

                  expect(gl_user.password).not_to eq(gl_user_2.password)
                end

                it "creates a user with dual LDAP and omniauth identities" do
                  expect(gl_user).to be_valid
                  expect(gl_user.username).to eql uid
                  expect(gl_user.name).to eql 'John Doe'
                  expect(gl_user.email).to eql 'johndoe@example.com'
                  expect(gl_user.identities.length).to be 2
                  identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                  expect(identities_as_hash).to match_array(
                    [
                      { provider: 'ldapmain', extern_uid: dn },
                      { provider: 'twitter', extern_uid: uid }
                    ]
                  )
                end

                it "has name and email set as synced" do
                  expect(gl_user.user_synced_attributes_metadata.name_synced).to be_truthy
                  expect(gl_user.user_synced_attributes_metadata.email_synced).to be_truthy
                end

                it "has name and email set as read-only" do
                  expect(gl_user.read_only_attribute?(:name)).to be_truthy
                  expect(gl_user.read_only_attribute?(:email)).to be_truthy
                end

                it "has synced attributes provider set to ldapmain" do
                  expect(gl_user.user_synced_attributes_metadata.provider).to eql 'ldapmain'
                end
              end

              context 'when the LDAP user is found by email address' do
                before do
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(nil)
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_email).with(uid, any_args).and_return(nil)
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_email).with(info_hash[:email], any_args).and_return(ldap_user)

                  oauth_user.save # rubocop:disable Rails/SaveBang
                end

                it 'creates the LDAP identity' do
                  identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                  expect(identities_as_hash).to include({ provider: 'ldapmain', extern_uid: dn })
                end
              end
            end

            context "and LDAP user has an account already" do
              let(:provider) { 'ldapmain' }

              before do
                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)
                stub_omniauth_config(sync_profile_attributes: true)
                allow(Gitlab.config.ldap).to receive(:enabled).and_return(true)
              end

              context 'when sync_name is disabled' do
                before do
                  stub_ldap_config(sync_name: false)
                end

                let!(:existing_user) { create(:omniauth_user, name: 'John Deo', email: 'john@example.com', extern_uid: dn, provider: 'ldapmain', username: 'john') }

                it "does not update the user name" do
                  oauth_user.save # rubocop:disable Rails/SaveBang

                  expect(gl_user).to be_valid
                  expect(gl_user.name).to eql 'John Deo'
                end
              end

              context 'when sync_name is enabled' do
                before do
                  stub_ldap_config(sync_name: true)
                end

                let!(:existing_user) { create(:omniauth_user, name: 'John Swift', email: 'john@example.com', extern_uid: dn, provider: 'ldapmain', username: 'john') }

                it "updates the user name" do
                  oauth_user.save # rubocop:disable Rails/SaveBang

                  expect(gl_user).to be_valid
                  expect(gl_user.name).to eql 'John'
                end
              end
            end

            context 'when an LDAP person is not found by uid' do
              it 'tries to find an LDAP person by email and adds the omniauth identity to the user' do
                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(nil)
                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_email).and_return(ldap_user)

                oauth_user.save # rubocop:disable Rails/SaveBang

                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array(result_identities(dn, uid))
              end

              context 'when also not found by email' do
                it 'tries to find an LDAP person by DN and adds the omniauth identity to the user' do
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(nil)
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_email).and_return(nil)
                  allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_dn).and_return(ldap_user)

                  oauth_user.save # rubocop:disable Rails/SaveBang

                  identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                  expect(identities_as_hash).to match_array(result_identities(dn, uid))
                end
              end
            end

            def result_identities(dn, uid)
              [
                { provider: 'ldapmain', extern_uid: dn },
                { provider: 'twitter', extern_uid: uid }
              ]
            end

            context 'when there is an LDAP connection error' do
              before do
                raise_ldap_connection_error
              end

              it 'does not save the identity' do
                oauth_user.save # rubocop:disable Rails/SaveBang

                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array([{ provider: 'twitter', extern_uid: uid }])
              end
            end
          end

          context "and a corresponding LDAP person with some values being nil" do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { uid }
              allow(ldap_user).to receive(:name) { nil }
              allow(ldap_user).to receive(:email) { nil }
              allow(ldap_user).to receive(:dn) { dn }

              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)

              oauth_user.save # rubocop:disable Rails/SaveBang
            end

            it "creates the user correctly" do
              expect(gl_user).to be_valid
              expect(gl_user.username).to eq(uid)
              expect(gl_user.name).to eq(info_hash[:name])
              expect(gl_user.email).to eq(info_hash[:email])
            end

            it "does not have the attributes not provided by LDAP set as synced" do
              expect(gl_user.user_synced_attributes_metadata.name_synced).to be_falsey
              expect(gl_user.user_synced_attributes_metadata.email_synced).to be_falsey
            end

            it "does not have the attributes not provided by LDAP set as read-only" do
              expect(gl_user.read_only_attribute?(:name)).to be_falsey
              expect(gl_user.read_only_attribute?(:email)).to be_falsey
            end
          end

          context 'and a corresponding LDAP person with a non-default username' do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { 'johndoe@example.com' }
              allow(ldap_user).to receive(:email) { %w[johndoe@example.com john2@example.com] }
              allow(ldap_user).to receive(:dn) { dn }
            end

            context 'and no account for the LDAP user' do
              it 'creates a user favoring the LDAP username and strips email domain' do
                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)

                oauth_user.save # rubocop:disable Rails/SaveBang

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'johndoe'
              end
            end
          end

          context "and no corresponding LDAP person" do
            before do
              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(nil)
              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_email).and_return(nil)
              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_dn).and_return(nil)
            end

            include_examples "to verify compliance with allow_single_sign_on"
          end
        end
      end

      context "with both auto_link_user and auto_link_ldap_user enabled" do
        before do
          stub_omniauth_config(auto_link_user: ['twitter'], auto_link_ldap_user: true)
        end

        context "and at least one LDAP provider is defined" do
          before do
            stub_ldap_config(providers: %w[ldapmain])
          end

          context "and a corresponding LDAP person" do
            before do
              allow(ldap_user).to receive_messages(
                uid: uid,
                username: uid,
                name: 'John Doe',
                email: ['John@mail.com'],
                dn: dn
              )
            end

            context "and no account for the LDAP user" do
              before do
                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)

                oauth_user.save # rubocop:disable Rails/SaveBang
              end

              it "creates a user with dual LDAP and omniauth identities" do
                expect(gl_user).to be_valid
                expect(gl_user.username).to eql uid
                expect(gl_user.name).to eql 'John Doe'
                expect(gl_user.email).to eql 'john@mail.com'
                expect(gl_user.identities.length).to be 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array(
                  [
                    { provider: 'ldapmain', extern_uid: dn },
                    { provider: 'twitter', extern_uid: uid }
                  ]
                )
              end

              it "has name and email set as synced" do
                expect(gl_user.user_synced_attributes_metadata.name_synced).to be_truthy
                expect(gl_user.user_synced_attributes_metadata.email_synced).to be_truthy
              end

              it "has name and email set as read-only" do
                expect(gl_user.read_only_attribute?(:name)).to be_truthy
                expect(gl_user.read_only_attribute?(:email)).to be_truthy
              end

              it "has synced attributes provider set to ldapmain" do
                expect(gl_user.user_synced_attributes_metadata.provider).to eql 'ldapmain'
              end
            end

            context "and LDAP user has an account already" do
              let!(:existing_user) { create(:omniauth_user, name: 'John Doe', email: 'john@mail.com', extern_uid: dn, provider: 'ldapmain', username: 'john') }

              before do
                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)

                oauth_user.save # rubocop:disable Rails/SaveBang
              end

              it "adds the omniauth identity to the LDAP account" do
                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'john'
                expect(gl_user.name).to eql 'John Doe'
                expect(gl_user.email).to eql 'john@mail.com'
                expect(gl_user.identities.length).to be 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array(
                  [
                    { provider: 'ldapmain', extern_uid: dn },
                    { provider: 'twitter', extern_uid: uid }
                  ]
                )
              end

              it "has name and email set as synced" do
                expect(gl_user.user_synced_attributes_metadata.name_synced).to be_truthy
                expect(gl_user.user_synced_attributes_metadata.email_synced).to be_truthy
              end

              it "has name and email set as read-only" do
                expect(gl_user.read_only_attribute?(:name)).to be_truthy
                expect(gl_user.read_only_attribute?(:email)).to be_truthy
              end
            end
          end
        end
      end
    end

    describe 'blocking' do
      let(:provider) { 'twitter' }

      before do
        stub_omniauth_config(allow_single_sign_on: ['twitter'])
      end

      shared_examples 'being blocked on creation' do
        context 'when blocking on creation' do
          it 'creates a blocked user' do
            oauth_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user).to be_blocked
          end

          context 'when a sign up user cap has been set up but has not been reached yet' do
            it 'still creates a blocked user' do
              stub_application_setting(new_user_signups_cap: 999)

              oauth_user.save # rubocop:disable Rails/SaveBang
              expect(gl_user).to be_valid
              expect(gl_user).to be_blocked
            end
          end
        end
      end

      shared_examples 'not being blocked on creation' do
        context 'when not blocking on creation' do
          it 'creates a non-blocked user' do
            oauth_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end
      end

      context 'signup with SAML' do
        let(:provider) { 'saml' }
        let(:block_auto_created_users) { false }

        before do
          stub_omniauth_config({
            allow_single_sign_on: ['saml'],
            auto_link_saml_user: true,
            block_auto_created_users: block_auto_created_users
          })
        end

        it_behaves_like 'being blocked on creation' do
          let(:block_auto_created_users) { true }
        end

        it_behaves_like 'not being blocked on creation' do
          let(:block_auto_created_users) { false }
        end

        it 'does not repeat the default user password' do
          oauth_user.save # rubocop:disable Rails/SaveBang
          oauth_user_2.save # rubocop:disable Rails/SaveBang

          expect(gl_user.password).not_to eq(gl_user_2.password)
        end
      end

      context 'signup with omniauth only' do
        it_behaves_like 'being blocked on creation' do
          before do
            stub_omniauth_config(block_auto_created_users: true)
          end
        end

        it_behaves_like 'not being blocked on creation' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end
        end
      end

      context 'signup with linked omniauth and LDAP account' do
        before do
          stub_omniauth_config(auto_link_ldap_user: true)
          stub_ldap_setting(enabled: true)
          allow(ldap_user).to receive(:uid) { uid }
          allow(ldap_user).to receive(:username) { uid }
          allow(ldap_user).to receive(:email) { ['johndoe@example.com', 'john2@example.com'] }
          allow(ldap_user).to receive(:dn) { dn }
          allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).and_return(ldap_user)
        end

        context "and no account for the LDAP user" do
          it_behaves_like 'being blocked on creation' do
            before do
              allow_next_instance_of(Gitlab::Auth::Ldap::Config) do |instance|
                allow(instance).to receive_messages(block_auto_created_users: true)
              end
            end
          end

          it_behaves_like 'not being blocked on creation' do
            before do
              allow_next_instance_of(Gitlab::Auth::Ldap::Config) do |instance|
                allow(instance).to receive_messages(block_auto_created_users: false)
              end
            end
          end
        end

        context 'and LDAP user has an account already' do
          let!(:existing_user) { create(:omniauth_user, email: 'john@example.com', extern_uid: dn, provider: 'ldapmain', username: 'john') }

          it_behaves_like 'not being blocked on creation' do
            before do
              allow_next_instance_of(Gitlab::Auth::Ldap::Config) do |instance|
                allow(instance).to receive_messages(block_auto_created_users: false)
              end
            end
          end

          it_behaves_like 'not being blocked on creation' do
            before do
              allow_next_instance_of(Gitlab::Auth::Ldap::Config) do |instance|
                allow(instance).to receive_messages(block_auto_created_users: true)
              end
            end
          end
        end
      end

      context 'sign-in' do
        before do
          oauth_user.save # rubocop:disable Rails/SaveBang
          oauth_user.gl_user.activate
        end

        it_behaves_like 'not being blocked on creation' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end
        end

        it_behaves_like 'not being blocked on creation' do
          before do
            stub_omniauth_config(block_auto_created_users: true)
          end
        end

        it_behaves_like 'not being blocked on creation' do
          before do
            allow_next_instance_of(Gitlab::Auth::Ldap::Config) do |instance|
              allow(instance).to receive_messages(block_auto_created_users: false)
            end
          end
        end

        it_behaves_like 'not being blocked on creation' do
          before do
            allow_next_instance_of(Gitlab::Auth::Ldap::Config) do |instance|
              allow(instance).to receive_messages(block_auto_created_users: true)
            end
          end
        end
      end
    end
  end

  describe 'ensure backwards compatibility with sync email from provider option' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    before do
      stub_omniauth_config(sync_email_from_provider: 'my-provider')
      stub_omniauth_config(sync_profile_from_provider: ['my-provider'])
    end

    context "when provider sets an email" do
      it "updates the user email" do
        expect(gl_user.email).to eq(info_hash[:email])
      end

      it "has email set as synced" do
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be_truthy
      end

      it "has email set as read-only" do
        expect(gl_user.read_only_attribute?(:email)).to be_truthy
      end

      it "has synced attributes provider set to my-provider" do
        expect(gl_user.user_synced_attributes_metadata.provider).to eql 'my-provider'
      end
    end

    context "when provider doesn't set an email" do
      before do
        info_hash.delete(:email)
      end

      it "does not update the user email" do
        expect(gl_user.email).not_to eq(info_hash[:email])
      end

      it "has email set as not synced" do
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be_falsey
      end

      it "does not have email set as read-only" do
        expect(gl_user.read_only_attribute?(:email)).to be_falsey
      end
    end
  end

  describe 'generating username' do
    context 'when no collision with existing user' do
      it 'generates the username with no counter' do
        expect(gl_user.username).to eq('johngitlab-ETC')
      end
    end

    context 'when collision with existing user' do
      it 'generates the username with a counter' do
        oauth_user.save # rubocop:disable Rails/SaveBang
        oauth_user2 = described_class.new(OmniAuth::AuthHash.new(uid: 'my-uid2', provider: provider, info: { nickname: 'johngitlab-ETC@othermail.com', email: 'john@othermail.com' }))

        expect(oauth_user2.gl_user.username).to eq('johngitlab-ETC1')
      end

      it 'generates the username with a counter for special characters' do
        oauth_user.save # rubocop:disable Rails/SaveBang -- not an ActiveRecord model, no save! method
        oauth_user2 = described_class.new(OmniAuth::AuthHash.new(uid: 'my-uid2', provider: provider, info: { nickname: 'johngitlab---ETC@othermail.com', email: 'john@othermail.com' }))

        expect(oauth_user2.gl_user.username).to eq('johngitlab-ETC1')
      end
    end

    context 'when username is a reserved word' do
      let(:info_hash) do
        {
          nickname: 'admin@othermail.com',
          email: 'admin@othermail.com'
        }
      end

      it 'generates the username with a counter' do
        expect(gl_user.username).to eq('admin1')
      end
    end

    context 'with leading or trailing _.- characters in username' do
      let(:info_hash) do
        {
          nickname: '___opie.-_!the$_#^^opossum---',
          email: 'admin@othermail.com'
        }
      end

      it 'creates valid user with sanitized username' do
        expect(gl_user).to be_valid
        expect(gl_user.username).to eq('opie.the_opossum')
      end
    end
  end

  describe 'updating email with sync profile' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    before do
      stub_omniauth_config(sync_profile_from_provider: ['my-provider'])
      stub_omniauth_config(sync_profile_attributes: true)
    end

    context "when provider sets an email" do
      it "updates the user email" do
        expect(gl_user.email).to eq(info_hash[:email])
      end

      it "has email set as synced" do
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be(true)
      end

      it "has email set as read-only" do
        expect(gl_user.read_only_attribute?(:email)).to be_truthy
      end

      it "has synced attributes provider set to my-provider" do
        expect(gl_user.user_synced_attributes_metadata.provider).to eql 'my-provider'
      end
    end

    context "when provider doesn't set an email" do
      before do
        info_hash.delete(:email)
      end

      it "does not update the user email" do
        expect(gl_user.email).not_to eq(info_hash[:email])
      end

      it "has email set as not synced" do
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be_falsey
      end

      it "does not have email set as read-only" do
        expect(gl_user.read_only_attribute?(:email)).to be_falsey
      end
    end
  end

  describe 'updating name' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    before do
      stub_omniauth_setting(sync_profile_from_provider: ['my-provider'])
      stub_omniauth_setting(sync_profile_attributes: true)
    end

    context "when provider sets a name" do
      it "updates the user name" do
        expect(gl_user.name).to eq(info_hash[:name])
      end
    end

    context "when provider doesn't set a name" do
      before do
        info_hash.delete(:name)
      end

      it "does not update the user name" do
        expect(gl_user.name).not_to eq(info_hash[:name])
        expect(gl_user.user_synced_attributes_metadata.name_synced).to be(false)
      end
    end
  end

  describe 'updating location' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    before do
      stub_omniauth_setting(sync_profile_from_provider: ['my-provider'])
      stub_omniauth_setting(sync_profile_attributes: true)
    end

    context "when provider sets a location" do
      it "updates the user location" do
        expect(gl_user.location).to eq(info_hash[:address][:locality] + ', ' + info_hash[:address][:country])
        expect(gl_user.user_synced_attributes_metadata.location_synced).to be(true)
      end
    end

    context "when provider doesn't set a location" do
      before do
        info_hash[:address].delete(:country)
        info_hash[:address].delete(:locality)
      end

      it "does not update the user location" do
        expect(gl_user.location).to be_blank
        expect(gl_user.user_synced_attributes_metadata.location_synced).to be(false)
      end
    end
  end

  describe 'updating user info' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    context "update all info" do
      before do
        stub_omniauth_setting(sync_profile_from_provider: ['my-provider'])
        stub_omniauth_setting(sync_profile_attributes: true)
      end

      it "updates the user email" do
        expect(gl_user.email).to eq(info_hash[:email])
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be(true)
      end

      it "updates the user name" do
        expect(gl_user.name).to eq(info_hash[:name])
        expect(gl_user.user_synced_attributes_metadata.name_synced).to be(true)
      end

      it "updates the user location" do
        expect(gl_user.location).to eq(info_hash[:address][:locality] + ', ' + info_hash[:address][:country])
        expect(gl_user.user_synced_attributes_metadata.location_synced).to be(true)
      end

      it "sets my-provider as the attributes provider" do
        expect(gl_user.user_synced_attributes_metadata.provider).to eql('my-provider')
      end

      it "updates the user organization and job title" do
        expect(gl_user.user_detail_organization).to eq(info_hash[:organization])
        expect(gl_user.job_title).to eq(info_hash[:job_title])
        expect(gl_user.user_synced_attributes_metadata.organization_synced).to be(true)
        expect(gl_user.user_synced_attributes_metadata.job_title_synced).to be(true)
      end

      context "when there is a mismatch with what attributes can be synced" do
        before do
          allow(UserSyncedAttributesMetadata).to receive(:syncable_attributes).and_return([:random_key])
          info_hash[:random_key] = "random value"
          allow_next_instance_of(Gitlab::Auth::OAuth::AuthHash) do |instance|
            allow(instance).to receive(:random_key).and_return(info_hash[:random_key])
          end
        end

        it "raises an error" do
          expect { oauth_user }.to raise_error Gitlab::Auth::OAuth::User::UnknownAttributeMappingError
        end
      end
    end

    context "update only requested info" do
      before do
        stub_omniauth_setting(sync_profile_from_provider: ['my-provider'])
        stub_omniauth_setting(sync_profile_attributes: %w[name location organization job_title])
      end

      it "updates the user name" do
        expect(gl_user.name).to eq(info_hash[:name])
        expect(gl_user.user_synced_attributes_metadata.name_synced).to be(true)
      end

      it "updates the user location" do
        expect(gl_user.location).to eq(info_hash[:address][:locality] + ', ' + info_hash[:address][:country])
        expect(gl_user.user_synced_attributes_metadata.location_synced).to be(true)
      end

      it "does not update the user email" do
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be(false)
      end

      it "updates the user organization and job title" do
        expect(gl_user.user_detail_organization).to eq(info_hash[:organization])
        expect(gl_user.job_title).to eq(info_hash[:job_title])
        expect(gl_user.user_synced_attributes_metadata.organization_synced).to be(true)
        expect(gl_user.user_synced_attributes_metadata.job_title_synced).to be(true)
      end
    end

    context "update default_scope" do
      before do
        stub_omniauth_setting(sync_profile_from_provider: ['my-provider'])
      end

      it "updates the user email" do
        expect(gl_user.email).to eq(info_hash[:email])
        expect(gl_user.user_synced_attributes_metadata.email_synced).to be(true)
      end
    end

    context "update no info when profile sync is nil" do
      it "does not update the user email" do
        expect(gl_user.email).not_to eq(info_hash[:email])
      end

      it "does not update the user name" do
        expect(gl_user.name).not_to eq(info_hash[:name])
      end

      it "does not update the user location" do
        expect(gl_user.location).not_to eq(info_hash[:address][:country])
      end

      it 'does not create associated user synced attributes metadata' do
        expect(gl_user.user_synced_attributes_metadata).to be_nil
      end
    end
  end

  context 'when gl_user is nil' do
    # We can't use `allow_next_instance_of` here because the stubbed method is called inside `initialize`.
    # When the class calls `gl_user` during `initialize`, the `nil` value is overwritten and we do not see expected results from the spec.
    # So we use `allow_any_instance_of` to preserve the `nil` value to test the behavior when `gl_user` is nil.

    # rubocop:disable RSpec/AnyInstanceOf
    before do
      allow_any_instance_of(described_class).to receive(:gl_user) { nil }
      allow_any_instance_of(described_class).to receive(:sync_profile_from_provider?) { true } # to make the code flow proceed until gl_user.build_user_synced_attributes_metadata is called
    end
    # rubocop:enable RSpec/AnyInstanceOf

    it 'does not raise NoMethodError' do
      expect { oauth_user }.not_to raise_error
    end
  end

  describe '._uid_and_provider' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    it 'normalizes extern_uid' do
      allow(oauth_user.auth_hash).to receive(:uid).and_return('MY-UID')
      expect(oauth_user.find_user).to eql gl_user
    end
  end

  describe '#find_ldap_person' do
    context 'when LDAP connection fails' do
      before do
        raise_ldap_connection_error
      end

      it 'returns nil' do
        adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
        hash = OmniAuth::AuthHash.new(uid: 'whatever', provider: 'ldapmain')

        expect(oauth_user.send(:find_ldap_person, hash, adapter)).to be_nil
      end
    end
  end

  describe "#bypass_two_factor?" do
    it "when with allow_bypass_two_factor disabled (Default)" do
      stub_omniauth_config(allow_bypass_two_factor: false)
      expect(oauth_user.bypass_two_factor?).to be_falsey
    end

    it "when with allow_bypass_two_factor enabled" do
      stub_omniauth_config(allow_bypass_two_factor: true)
      expect(oauth_user.bypass_two_factor?).to be_truthy
    end

    it "when provider in allow_bypass_two_factor array" do
      stub_omniauth_config(allow_bypass_two_factor: [provider])
      expect(oauth_user.bypass_two_factor?).to be_truthy
    end

    it "when provider not in allow_bypass_two_factor array" do
      stub_omniauth_config(allow_bypass_two_factor: ["foo"])
      expect(oauth_user.bypass_two_factor?).to be_falsey
    end
  end

  describe '#protocol_name' do
    it 'is OAuth' do
      expect(oauth_user.protocol_name).to eq('OAuth')
    end
  end
end
