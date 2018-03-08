require 'spec_helper'

describe Gitlab::Auth::OAuth::User do
  let(:oauth_user) { described_class.new(auth_hash) }
  let(:gl_user) { oauth_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:dn) { 'uid=user1,ou=people,dc=example' }
  let(:provider) { 'my-provider' }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash) }
  let(:info_hash) do
    {
      nickname: '-john+gitlab-ETC%.git@gmail.com',
      name: 'John',
      email: 'john@mail.com',
      address: {
        locality: 'locality',
        country: 'country'
      }
    }
  end
  let(:ldap_user) { Gitlab::Auth::LDAP::Person.new(Net::LDAP::Entry.new, 'ldapmain') }

  describe '#persisted?' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    it "finds an existing user based on uid and provider (facebook)" do
      expect( oauth_user.persisted? ).to be_truthy
    end

    it 'returns false if user is not found in database' do
      allow(auth_hash).to receive(:uid).and_return('non-existing')
      expect( oauth_user.persisted? ).to be_falsey
    end
  end

  def stub_omniauth_config(messages)
    allow(Gitlab.config.omniauth).to receive_messages(messages)
  end

  describe '#save' do
    def stub_ldap_config(messages)
      allow(Gitlab::Auth::LDAP::Config).to receive_messages(messages)
    end

    let(:provider) { 'twitter' }

    describe 'when account exists on server' do
      it 'does not mark the user as external' do
        create(:omniauth_user, extern_uid: 'my-uid', provider: provider)
        stub_omniauth_config(allow_single_sign_on: [provider], external_providers: [provider])

        oauth_user.save

        expect(gl_user).to be_valid
        expect(gl_user.external).to be_falsey
      end
    end

    describe 'signup' do
      context 'when signup is disabled' do
        before do
          stub_application_setting signup_enabled: false
        end

        it 'creates the user' do
          stub_omniauth_config(allow_single_sign_on: [provider])

          oauth_user.save

          expect(gl_user).to be_persisted
        end
      end

      context 'when user confirmation email is enabled' do
        before do
          stub_application_setting send_user_confirmation_email: true
        end

        it 'creates and confirms the user anyway' do
          stub_omniauth_config(allow_single_sign_on: [provider])

          oauth_user.save

          expect(gl_user).to be_persisted
          expect(gl_user).to be_confirmed
        end
      end

      it 'marks user as having password_automatically_set' do
        stub_omniauth_config(allow_single_sign_on: [provider], external_providers: [provider])

        oauth_user.save

        expect(gl_user).to be_persisted
        expect(gl_user).to be_password_automatically_set
      end

      shared_examples 'to verify compliance with allow_single_sign_on' do
        context 'provider is marked as external' do
          it 'marks user as external' do
            stub_omniauth_config(allow_single_sign_on: [provider], external_providers: [provider])
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user.external).to be_truthy
          end
        end

        context 'provider was external, now has been removed' do
          it 'does not mark external user as internal' do
            create(:omniauth_user, extern_uid: 'my-uid', provider: provider, external: true)
            stub_omniauth_config(allow_single_sign_on: [provider], external_providers: ['facebook'])
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user.external).to be_truthy
          end
        end

        context 'provider is not external' do
          context 'when adding a new OAuth identity' do
            it 'does not promote an external user to internal' do
              user = create(:user, email: 'john@mail.com', external: true)
              user.identities.create(provider: provider, extern_uid: uid)

              oauth_user.save
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
            oauth_user.save

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
            oauth_user.save

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
            expect { oauth_user.save }.to raise_error StandardError
          end
        end

        context 'with old allow_single_sign_on disabled (Default)' do
          before do
            stub_omniauth_config(allow_single_sign_on: false)
          end

          it 'throws an error' do
            expect { oauth_user.save }.to raise_error StandardError
          end
        end
      end

      context "with auto_link_ldap_user disabled (default)" do
        before do
          stub_omniauth_config(auto_link_ldap_user: false)
        end

        include_examples "to verify compliance with allow_single_sign_on"
      end

      context "with auto_link_ldap_user enabled" do
        before do
          stub_omniauth_config(auto_link_ldap_user: true)
        end

        context "and no LDAP provider defined" do
          before do
            stub_ldap_config(providers: [])
          end

          include_examples "to verify compliance with allow_single_sign_on"
        end

        context "and at least one LDAP provider is defined" do
          before do
            stub_ldap_config(providers: %w(ldapmain))
          end

          context "and a corresponding LDAP person" do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { uid }
              allow(ldap_user).to receive(:email) { ['johndoe@example.com', 'john2@example.com'] }
              allow(ldap_user).to receive(:dn) { dn }
            end

            context "and no account for the LDAP user" do
              before do
                allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_uid).and_return(ldap_user)

                oauth_user.save
              end

              it "creates a user with dual LDAP and omniauth identities" do
                expect(gl_user).to be_valid
                expect(gl_user.username).to eql uid
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

              it "has email set as synced" do
                expect(gl_user.user_synced_attributes_metadata.email_synced).to be_truthy
              end

              it "has email set as read-only" do
                expect(gl_user.read_only_attribute?(:email)).to be_truthy
              end

              it "has synced attributes provider set to ldapmain" do
                expect(gl_user.user_synced_attributes_metadata.provider).to eql 'ldapmain'
              end
            end

            context "and LDAP user has an account already" do
              let!(:existing_user) { create(:omniauth_user, email: 'john@example.com', extern_uid: dn, provider: 'ldapmain', username: 'john') }
              it "adds the omniauth identity to the LDAP account" do
                allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_uid).and_return(ldap_user)

                oauth_user.save

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'john'
                expect(gl_user.email).to eql 'john@example.com'
                expect(gl_user.identities.length).to be 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array(
                  [
                    { provider: 'ldapmain', extern_uid: dn },
                    { provider: 'twitter', extern_uid: uid }
                  ]
                )
              end
            end

            context 'when an LDAP person is not found by uid' do
              it 'tries to find an LDAP person by DN and adds the omniauth identity to the user' do
                allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_uid).and_return(nil)
                allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(ldap_user)

                oauth_user.save

                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash)
                  .to match_array(
                    [
                      { provider: 'ldapmain', extern_uid: dn },
                      { provider: 'twitter', extern_uid: uid }
                    ]
                  )
              end
            end
          end

          context 'and a corresponding LDAP person with a non-default username' do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { 'johndoe@example.com' }
              allow(ldap_user).to receive(:email) { %w(johndoe@example.com john2@example.com) }
              allow(ldap_user).to receive(:dn) { dn }
            end

            context 'and no account for the LDAP user' do
              it 'creates a user favoring the LDAP username and strips email domain' do
                allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_uid).and_return(ldap_user)

                oauth_user.save

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'johndoe'
              end
            end
          end

          context "and no corresponding LDAP person" do
            before do
              allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_uid).and_return(nil)
            end

            include_examples "to verify compliance with allow_single_sign_on"
          end
        end
      end
    end

    describe 'blocking' do
      let(:provider) { 'twitter' }

      before do
        stub_omniauth_config(allow_single_sign_on: ['twitter'])
      end

      context 'signup with omniauth only' do
        context 'dont block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: true)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).to be_blocked
          end
        end
      end

      context 'signup with linked omniauth and LDAP account' do
        before do
          stub_omniauth_config(auto_link_ldap_user: true)
          allow(ldap_user).to receive(:uid) { uid }
          allow(ldap_user).to receive(:username) { uid }
          allow(ldap_user).to receive(:email) { ['johndoe@example.com', 'john2@example.com'] }
          allow(ldap_user).to receive(:dn) { dn }
          allow(Gitlab::Auth::LDAP::Person).to receive(:find_by_uid).and_return(ldap_user)
        end

        context "and no account for the LDAP user" do
          context 'dont block on create (LDAP)' do
            before do
              allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(block_auto_created_users: false)
            end

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end

          context 'block on create (LDAP)' do
            before do
              allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(block_auto_created_users: true)
            end

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).to be_blocked
            end
          end
        end

        context 'and LDAP user has an account already' do
          let!(:existing_user) { create(:omniauth_user, email: 'john@example.com', extern_uid: dn, provider: 'ldapmain', username: 'john') }

          context 'dont block on create (LDAP)' do
            before do
              allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(block_auto_created_users: false)
            end

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end

          context 'block on create (LDAP)' do
            before do
              allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(block_auto_created_users: true)
            end

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end
        end
      end

      context 'sign-in' do
        before do
          oauth_user.save
          oauth_user.gl_user.activate
        end

        context 'dont block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: true)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'dont block on create (LDAP)' do
          before do
            allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(block_auto_created_users: false)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create (LDAP)' do
          before do
            allow_any_instance_of(Gitlab::Auth::LDAP::Config).to receive_messages(block_auto_created_users: true)
          end

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end
      end
    end
  end

  describe 'ensure backwards compatibility with with sync email from provider option' do
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
        oauth_user.save
        oauth_user2 = described_class.new(OmniAuth::AuthHash.new(uid: 'my-uid2', provider: provider, info: { nickname: 'johngitlab-ETC@othermail.com', email: 'john@othermail.com' }))

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
        expect(gl_user.location).to be_nil
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
    end

    context "update only requested info" do
      before do
        stub_omniauth_setting(sync_profile_from_provider: ['my-provider'])
        stub_omniauth_setting(sync_profile_attributes: %w(name location))
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
      it "does not have sync_attribute" do
        expect(gl_user.user_synced_attributes_metadata).to be(nil)
      end

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

  describe '.find_by_uid_and_provider' do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    it 'normalizes extern_uid' do
      allow(oauth_user.auth_hash).to receive(:uid).and_return('MY-UID')
      expect(oauth_user.find_user).to eql gl_user
    end
  end
end
