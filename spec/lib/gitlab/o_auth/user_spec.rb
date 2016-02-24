require 'spec_helper'

describe Gitlab::OAuth::User, lib: true do
  let(:oauth_user) { Gitlab::OAuth::User.new(auth_hash) }
  let(:gl_user) { oauth_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:provider) { 'my-provider' }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash) }
  let(:info_hash) do
    {
      nickname: '-john+gitlab-ETC%.git@gmail.com',
      name: 'John',
      email: 'john@mail.com'
    }
  end
  let(:ldap_user) { Gitlab::LDAP::Person.new(Net::LDAP::Entry.new, 'ldapmain') }

  describe :persisted? do
    let!(:existing_user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'my-provider') }

    it "finds an existing user based on uid and provider (facebook)" do
      expect( oauth_user.persisted? ).to be_truthy
    end

    it "returns false if use is not found in database" do
      allow(auth_hash).to receive(:uid).and_return('non-existing')
      expect( oauth_user.persisted? ).to be_falsey
    end
  end

  describe :save do
    def stub_omniauth_config(messages)
      allow(Gitlab.config.omniauth).to receive_messages(messages)
    end

    def stub_ldap_config(messages)
      allow(Gitlab::LDAP::Config).to receive_messages(messages)
    end

    let(:provider) { 'twitter' }

    describe 'signup' do
      shared_examples "to verify compliance with allow_single_sign_on" do
        context "with new allow_single_sign_on enabled syntax" do
          before { stub_omniauth_config(allow_single_sign_on: ['twitter']) }

          it "creates a user from Omniauth" do
            oauth_user.save

            expect(gl_user).to be_valid
            identity = gl_user.identities.first
            expect(identity.extern_uid).to eql uid
            expect(identity.provider).to eql 'twitter'
          end
        end

        context "with old allow_single_sign_on enabled syntax" do
          before { stub_omniauth_config(allow_single_sign_on: true) }

          it "creates a user from Omniauth" do
            oauth_user.save

            expect(gl_user).to be_valid
            identity = gl_user.identities.first
            expect(identity.extern_uid).to eql uid
            expect(identity.provider).to eql 'twitter'
          end
        end

        context "with new allow_single_sign_on disabled syntax" do
          before { stub_omniauth_config(allow_single_sign_on: []) }
          it "throws an error" do
            expect{ oauth_user.save }.to raise_error StandardError
          end
        end

        context "with old allow_single_sign_on disabled (Default)" do
          before { stub_omniauth_config(allow_single_sign_on: false) }
          it "throws an error" do
            expect{ oauth_user.save }.to raise_error StandardError
          end
        end
      end

      context "with auto_link_ldap_user disabled (default)" do
        before { stub_omniauth_config(auto_link_ldap_user: false) }
        include_examples "to verify compliance with allow_single_sign_on"
      end

      context "with auto_link_ldap_user enabled" do
        before { stub_omniauth_config(auto_link_ldap_user: true) }

        context "and no LDAP provider defined" do
          before { stub_ldap_config(providers: []) }

          include_examples "to verify compliance with allow_single_sign_on"
        end

        context "and at least one LDAP provider is defined" do
          before { stub_ldap_config(providers: %w(ldapmain)) }

          context "and a corresponding LDAP person" do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { uid }
              allow(ldap_user).to receive(:email) { ['johndoe@example.com','john2@example.com'] }
              allow(ldap_user).to receive(:dn) { 'uid=user1,ou=People,dc=example' }
              allow(Gitlab::LDAP::Person).to receive(:find_by_uid).and_return(ldap_user)
            end

            context "and no account for the LDAP user" do

              it "creates a user with dual LDAP and omniauth identities" do
                oauth_user.save

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql uid
                expect(gl_user.email).to eql 'johndoe@example.com'
                expect(gl_user.identities.length).to eql 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array(
                  [ { provider: 'ldapmain', extern_uid: 'uid=user1,ou=People,dc=example' },
                    { provider: 'twitter', extern_uid: uid }
                  ])
              end
            end

            context "and LDAP user has an account already" do
              let!(:existing_user) { create(:omniauth_user, email: 'john@example.com', extern_uid: 'uid=user1,ou=People,dc=example', provider: 'ldapmain', username: 'john') }
              it "adds the omniauth identity to the LDAP account" do
                oauth_user.save

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'john'
                expect(gl_user.email).to eql 'john@example.com'
                expect(gl_user.identities.length).to eql 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array(
                  [ { provider: 'ldapmain', extern_uid: 'uid=user1,ou=People,dc=example' },
                    { provider: 'twitter', extern_uid: uid }
                  ])
              end
            end
          end

          context "and no corresponding LDAP person" do
            before { allow(Gitlab::LDAP::Person).to receive(:find_by_uid).and_return(nil) }

            include_examples "to verify compliance with allow_single_sign_on"
          end
        end
      end

    end

    describe 'blocking' do
      let(:provider) { 'twitter' }
      before { stub_omniauth_config(allow_single_sign_on: ['twitter']) }

      context 'signup with omniauth only' do
        context 'dont block on create' do
          before { stub_omniauth_config(block_auto_created_users: false) }

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before { stub_omniauth_config(block_auto_created_users: true) }

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
          allow(ldap_user).to receive(:email) { ['johndoe@example.com','john2@example.com'] }
          allow(ldap_user).to receive(:dn) { 'uid=user1,ou=People,dc=example' }
          allow(oauth_user).to receive(:ldap_person).and_return(ldap_user)
        end

        context "and no account for the LDAP user" do
          context 'dont block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: false) }

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end

          context 'block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: true) }

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).to be_blocked
            end
          end
        end

        context 'and LDAP user has an account already' do
          let!(:existing_user) { create(:omniauth_user, email: 'john@example.com', extern_uid: 'uid=user1,ou=People,dc=example', provider: 'ldapmain', username: 'john') }

          context 'dont block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: false) }

            it do
              oauth_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end

          context 'block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: true) }

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
          before { stub_omniauth_config(block_auto_created_users: false) }

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before { stub_omniauth_config(block_auto_created_users: true) }

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'dont block on create (LDAP)' do
          before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: false) }

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create (LDAP)' do
          before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: true) }

          it do
            oauth_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end
      end
    end
  end
end
