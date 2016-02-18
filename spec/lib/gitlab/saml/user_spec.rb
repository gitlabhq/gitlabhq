require 'spec_helper'

describe Gitlab::Saml::User, lib: true do
  let(:saml_user) { described_class.new(auth_hash) }
  let(:gl_user) { saml_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:provider) { 'saml' }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash) }
  let(:info_hash) do
    {
      name: 'John',
      email: 'john@mail.com'
    }
  end
  let(:ldap_user) { Gitlab::LDAP::Person.new(Net::LDAP::Entry.new, 'ldapmain') }

  describe '#save' do
    def stub_omniauth_config(messages)
      allow(Gitlab.config.omniauth).to receive_messages(messages)
    end

    def stub_ldap_config(messages)
      allow(Gitlab::LDAP::Config).to receive_messages(messages)
    end

    describe 'account exists on server' do
      before { stub_omniauth_config({ allow_single_sign_on: ['saml'], auto_link_saml_user: true }) }
      context 'and should bind with SAML' do
        let!(:existing_user) { create(:user, email: 'john@mail.com', username: 'john') }
        it 'adds the SAML identity to the existing user' do
          saml_user.save
          expect(gl_user).to be_valid
          expect(gl_user).to eq existing_user
          identity = gl_user.identities.first
          expect(identity.extern_uid).to eql uid
          expect(identity.provider).to eql 'saml'
        end
      end
    end

    describe 'no account exists on server' do
      shared_examples 'to verify compliance with allow_single_sign_on' do
        context 'with allow_single_sign_on enabled' do
          before { stub_omniauth_config(allow_single_sign_on: ['saml']) }

          it 'creates a user from SAML' do
            saml_user.save

            expect(gl_user).to be_valid
            identity = gl_user.identities.first
            expect(identity.extern_uid).to eql uid
            expect(identity.provider).to eql 'saml'
          end
        end

        context 'with allow_single_sign_on default (["saml"])' do
          before { stub_omniauth_config(allow_single_sign_on: ['saml']) }
          it 'should not throw an error' do
            expect{ saml_user.save }.not_to raise_error
          end
        end

        context 'with allow_single_sign_on disabled' do
          before { stub_omniauth_config(allow_single_sign_on: false) }
          it 'should throw an error' do
            expect{ saml_user.save }.to raise_error StandardError
          end
        end
      end

      context 'with auto_link_ldap_user disabled (default)' do
        before { stub_omniauth_config({ auto_link_ldap_user: false, auto_link_saml_user: false, allow_single_sign_on: ['saml'] }) }
        include_examples 'to verify compliance with allow_single_sign_on'
      end

      context 'with auto_link_ldap_user enabled' do
        before { stub_omniauth_config({ auto_link_ldap_user: true, auto_link_saml_user: false }) }

        context 'and no LDAP provider defined' do
          before { stub_ldap_config(providers: []) }

          include_examples 'to verify compliance with allow_single_sign_on'
        end

        context 'and at least one LDAP provider is defined' do
          before { stub_ldap_config(providers: %w(ldapmain)) }

          context 'and a corresponding LDAP person' do
            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { uid }
              allow(ldap_user).to receive(:email) { ['johndoe@example.com','john2@example.com'] }
              allow(ldap_user).to receive(:dn) { 'uid=user1,ou=People,dc=example' }
              allow(Gitlab::LDAP::Person).to receive(:find_by_uid).and_return(ldap_user)
            end

            context 'and no account for the LDAP user' do

              it 'creates a user with dual LDAP and SAML identities' do
                saml_user.save

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql uid
                expect(gl_user.email).to eql 'johndoe@example.com'
                expect(gl_user.identities.length).to eql 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array([ { provider: 'ldapmain', extern_uid: 'uid=user1,ou=People,dc=example' },
                                                            { provider: 'saml', extern_uid: uid }
                                                          ])
              end
            end

            context 'and LDAP user has an account already' do
              let!(:existing_user) { create(:omniauth_user, email: 'john@example.com', extern_uid: 'uid=user1,ou=People,dc=example', provider: 'ldapmain', username: 'john') }
              it "adds the omniauth identity to the LDAP account" do
                saml_user.save

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'john'
                expect(gl_user.email).to eql 'john@example.com'
                expect(gl_user.identities.length).to eql 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array([ { provider: 'ldapmain', extern_uid: 'uid=user1,ou=People,dc=example' },
                                                            { provider: 'saml', extern_uid: uid }
                                                          ])
              end
            end
          end

          context 'and no corresponding LDAP person' do
            before { allow(Gitlab::LDAP::Person).to receive(:find_by_uid).and_return(nil) }

            include_examples 'to verify compliance with allow_single_sign_on'
          end
        end
      end

    end

    describe 'blocking' do
      before { stub_omniauth_config({ allow_saml_sign_up: true, auto_link_saml_user: true }) }

      context 'signup with SAML only' do
        context 'dont block on create' do
          before { stub_omniauth_config(block_auto_created_users: false) }

          it 'should not block the user' do
            saml_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before { stub_omniauth_config(block_auto_created_users: true) }

          it 'should block user' do
            saml_user.save
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
          allow(saml_user).to receive(:ldap_person).and_return(ldap_user)
        end

        context "and no account for the LDAP user" do
          context 'dont block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: false) }

            it do
              saml_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end

          context 'block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: true) }

            it do
              saml_user.save
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
              saml_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end

          context 'block on create (LDAP)' do
            before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: true) }

            it do
              saml_user.save
              expect(gl_user).to be_valid
              expect(gl_user).not_to be_blocked
            end
          end
        end
      end


      context 'sign-in' do
        before do
          saml_user.save
          saml_user.gl_user.activate
        end

        context 'dont block on create' do
          before { stub_omniauth_config(block_auto_created_users: false) }

          it do
            saml_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before { stub_omniauth_config(block_auto_created_users: true) }

          it do
            saml_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'dont block on create (LDAP)' do
          before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: false) }

          it do
            saml_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create (LDAP)' do
          before { allow_any_instance_of(Gitlab::LDAP::Config).to receive_messages(block_auto_created_users: true) }

          it do
            saml_user.save
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end
      end
    end
  end
end
