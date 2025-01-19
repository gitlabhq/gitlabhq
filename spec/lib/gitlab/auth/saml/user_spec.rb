# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::User, feature_category: :system_access do
  include LdapHelpers
  include LoginHelpers

  let_it_be(:organization) { create(:organization) }
  let(:saml_user) { described_class.new(auth_hash, organization_id: organization.id) }
  let(:gl_user) { saml_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:dn) { 'uid=user1,ou=people,dc=example' }
  let(:provider) { 'saml' }
  let(:raw_info_attr) { { 'groups' => %w[Developers Freelancers Designers] } }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash, extra: { raw_info: OneLogin::RubySaml::Attributes.new(raw_info_attr) }) }
  let(:info_hash) do
    {
      name: 'John',
      email: 'john@mail.com'
    }
  end

  let(:ldap_user) { Gitlab::Auth::Ldap::Person.new(Net::LDAP::Entry.new, 'ldapmain') }

  describe '#save' do
    before do
      stub_basic_saml_config
    end

    describe 'account exists on server' do
      before do
        stub_omniauth_config({ allow_single_sign_on: ['saml'], auto_link_saml_user: true })
      end

      let!(:existing_user) { create(:user, email: 'john@mail.com', username: 'john') }

      context 'and should bind with SAML' do
        it 'adds the SAML identity to the existing user' do
          saml_user.save # rubocop:disable Rails/SaveBang
          expect(gl_user).to be_valid
          expect(gl_user).to eq existing_user
          expect(gl_user.external).to be false
          identity = gl_user.identities.first
          expect(identity.extern_uid).to eql uid
          expect(identity.provider).to eql 'saml'
        end
      end

      context 'external groups' do
        context 'no external groups configuration is defined' do
          it 'does not mark the user as external' do
            saml_user.save # rubocop:disable Rails/SaveBang -- Not ActiveRecord object
            expect(gl_user).to be_valid
            expect(gl_user.external).to be false
          end

          it 'does not change a user manually set as external' do
            existing_user.update!(external: true)

            saml_user.save # rubocop:disable Rails/SaveBang -- Not ActiveRecord object
            expect(gl_user).to be_valid
            expect(gl_user.external).to be true
          end
        end

        context 'are defined' do
          before do
            stub_saml_group_config(%w[Freelancers])
          end

          it 'marks the user as external' do
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user.external).to be_truthy
          end

          context 'are defined but the user does not belong there' do
            it 'does not mark the user as external' do
              stub_saml_group_config(%w[Interns])
              saml_user.save # rubocop:disable Rails/SaveBang -- Not ActiveRecord object
              expect(gl_user).to be_valid
              expect(gl_user.external).to be false
            end
          end
        end

        context 'when the external_provider config is set to saml' do
          before do
            stub_omniauth_saml_config(external_providers: [provider], block_auto_created_users: false)
          end

          context 'when an existing saml external_user is removed from their external_group' do
            before do
              stub_saml_group_config([])
            end

            it 'retains the external:true attribute', :aggregate_failures do
              saml_user.save # rubocop:disable Rails/SaveBang -- Gitlab::Auth::OAuth::User#save is a custom method
              expect(gl_user).to eq existing_user
              expect(gl_user).to be_valid
              expect(gl_user.external).to be_truthy
            end
          end
        end
      end
    end

    describe 'no account exists on server' do
      shared_examples 'to verify compliance with allow_single_sign_on' do
        context 'with allow_single_sign_on enabled' do
          before do
            stub_omniauth_config(allow_single_sign_on: ['saml'])
          end

          it 'creates a user from SAML' do
            saml_user.save # rubocop:disable Rails/SaveBang

            expect(gl_user).to be_valid
            identity = gl_user.identities.first
            expect(identity.extern_uid).to eql uid
            expect(identity.provider).to eql 'saml'
          end
        end

        context 'with allow_single_sign_on default (["saml"])' do
          before do
            stub_omniauth_config(allow_single_sign_on: ['saml'])
          end

          it 'does not throw an error' do
            expect { saml_user.save }.not_to raise_error # rubocop:disable Rails/SaveBang
          end
        end

        context 'with allow_single_sign_on disabled' do
          before do
            stub_omniauth_config(allow_single_sign_on: false)
          end

          it 'throws an error' do
            expect { saml_user.save }.to raise_error StandardError # rubocop:disable Rails/SaveBang
          end
        end
      end

      context 'external groups' do
        context 'are defined' do
          it 'marks the user as external' do
            stub_saml_group_config(%w[Freelancers])
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user.external).to be_truthy
          end
        end

        context 'are defined but the user does not belong there' do
          it 'does not mark the user as external' do
            stub_saml_group_config(%w[Interns])
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user.external).to be false
          end
        end
      end

      context 'with auto_link_ldap_user disabled (default)' do
        before do
          stub_omniauth_config({ auto_link_ldap_user: false, auto_link_saml_user: false, allow_single_sign_on: ['saml'] })
        end

        include_examples 'to verify compliance with allow_single_sign_on'
      end

      context 'with auto_link_ldap_user enabled' do
        before do
          stub_omniauth_config({ auto_link_ldap_user: true, auto_link_saml_user: false })
        end

        context 'and at least one LDAP provider is defined' do
          before do
            stub_ldap_config(providers: %w[ldapmain])
          end

          context 'and a corresponding LDAP person' do
            let(:adapter) { ldap_adapter('ldapmain') }

            before do
              allow(ldap_user).to receive(:uid) { uid }
              allow(ldap_user).to receive(:username) { uid }
              allow(ldap_user).to receive(:email) { %w[john@mail.com john2@example.com] }
              allow(ldap_user).to receive(:dn) { dn }
              allow(Gitlab::Auth::Ldap::Adapter).to receive(:new).and_return(adapter)
              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).with(uid, adapter).and_return(ldap_user)
              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_dn).with(dn, adapter).and_return(ldap_user)
              allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_email).with('john@mail.com', adapter).and_return(ldap_user)
            end

            context 'and no account for the LDAP user' do
              it 'creates a user with dual LDAP and SAML identities' do
                saml_user.save # rubocop:disable Rails/SaveBang

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql uid
                expect(gl_user.email).to eql 'john@mail.com'
                expect(gl_user.identities.length).to be 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array([{ provider: 'ldapmain', extern_uid: dn },
                                                           { provider: 'saml', extern_uid: uid }])
              end
            end

            context 'and LDAP user has an account already' do
              let(:auth_hash_base_attributes) do
                {
                  uid: uid,
                  provider: provider,
                  info: info_hash,
                  extra: {
                    raw_info: OneLogin::RubySaml::Attributes.new(
                      { 'groups' => %w[Developers Freelancers Designers] }
                    )
                  }
                }
              end

              let(:auth_hash) { OmniAuth::AuthHash.new(auth_hash_base_attributes) }
              let(:uid_types) { %w[uid dn email] }

              before do
                create(
                  :omniauth_user,
                  email: 'john@mail.com',
                  extern_uid: dn,
                  provider: 'ldapmain',
                  username: 'john'
                )
              end

              shared_examples 'find LDAP person' do |uid_type, uid|
                let(:auth_hash) { OmniAuth::AuthHash.new(auth_hash_base_attributes.merge(uid: extern_uid)) }

                before do
                  nil_types = uid_types - [uid_type]

                  nil_types.each do |type|
                    allow(Gitlab::Auth::Ldap::Person).to receive(:"find_by_#{type}").and_return(nil)
                  end

                  allow(Gitlab::Auth::Ldap::Person).to receive(:"find_by_#{uid_type}").and_return(ldap_user)
                end

                it 'adds the omniauth identity to the LDAP account' do
                  identities = [
                    { provider: 'ldapmain', extern_uid: dn },
                    { provider: 'saml', extern_uid: extern_uid }
                  ]

                  identities_as_hash = gl_user.identities.map do |id|
                    { provider: id.provider, extern_uid: id.extern_uid }
                  end

                  saml_user.save # rubocop:disable Rails/SaveBang

                  expect(gl_user).to be_valid
                  expect(gl_user.username).to eql 'john'
                  expect(gl_user.email).to eql 'john@mail.com'
                  expect(gl_user.identities.length).to be 2
                  expect(identities_as_hash).to match_array(identities)
                end
              end

              context 'when uid is an uid' do
                it_behaves_like 'find LDAP person', 'uid' do
                  let(:extern_uid) { uid }
                end
              end

              context 'when uid is a dn' do
                it_behaves_like 'find LDAP person', 'dn' do
                  let(:extern_uid) { dn }
                end
              end

              context 'when uid is an email' do
                it_behaves_like 'find LDAP person', 'email' do
                  let(:extern_uid) { 'john@mail.com' }
                end
              end

              it 'adds the omniauth identity to the LDAP account' do
                saml_user.save # rubocop:disable Rails/SaveBang

                expect(gl_user).to be_valid
                expect(gl_user.username).to eql 'john'
                expect(gl_user.email).to eql 'john@mail.com'
                expect(gl_user.identities.length).to be 2
                identities_as_hash = gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array([{ provider: 'ldapmain', extern_uid: dn },
                                                           { provider: 'saml', extern_uid: uid }])
              end

              it 'saves successfully on subsequent tries, when both identities are present' do
                saml_user.save # rubocop:disable Rails/SaveBang
                local_saml_user = described_class.new(auth_hash)
                local_saml_user.save # rubocop:disable Rails/SaveBang

                expect(local_saml_user.gl_user).to be_valid
                expect(local_saml_user.gl_user).to be_persisted
              end
            end

            context 'user has SAML user, and wants to add their LDAP identity' do
              it 'adds the LDAP identity to the existing SAML user' do
                create(:omniauth_user, email: 'john@mail.com', extern_uid: dn, provider: 'saml', username: 'john')

                allow(Gitlab::Auth::Ldap::Person).to receive(:find_by_uid).with(dn, adapter).and_return(ldap_user)

                local_hash = OmniAuth::AuthHash.new(uid: dn, provider: provider, info: info_hash)
                local_saml_user = described_class.new(local_hash)

                local_saml_user.save # rubocop:disable Rails/SaveBang
                local_gl_user = local_saml_user.gl_user

                expect(local_gl_user).to be_valid
                expect(local_gl_user.identities.length).to be 2
                identities_as_hash = local_gl_user.identities.map { |id| { provider: id.provider, extern_uid: id.extern_uid } }
                expect(identities_as_hash).to match_array([{ provider: 'ldapmain', extern_uid: dn },
                                                           { provider: 'saml', extern_uid: dn }])
              end
            end
          end
        end
      end

      context 'when signup is disabled' do
        before do
          stub_application_setting signup_enabled: false
        end

        it 'creates the user' do
          saml_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_persisted
        end
      end

      context 'when user confirmation email is enabled' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'hard')
        end

        it 'creates and confirms the user anyway' do
          saml_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_persisted
          expect(gl_user).to be_confirmed
        end
      end

      context 'when the current minimum password length is different from the default minimum password length' do
        before do
          stub_application_setting minimum_password_length: 21
        end

        it 'creates the user' do
          saml_user.save # rubocop:disable Rails/SaveBang

          expect(gl_user).to be_persisted
        end
      end
    end

    describe 'blocking' do
      before do
        stub_omniauth_config({ allow_single_sign_on: ['saml'], auto_link_saml_user: true })
      end

      context 'signup with SAML only' do
        context 'dont block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end

          it 'does not block the user' do
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: true)
          end

          it 'blocks user' do
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user).to be_blocked
          end
        end
      end

      context 'sign-in' do
        before do
          saml_user.save # rubocop:disable Rails/SaveBang
          saml_user.gl_user.activate
        end

        context 'dont block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end

          it do
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end

        context 'block on create' do
          before do
            stub_omniauth_config(block_auto_created_users: true)
          end

          it do
            saml_user.save # rubocop:disable Rails/SaveBang
            expect(gl_user).to be_valid
            expect(gl_user).not_to be_blocked
          end
        end
      end
    end
  end

  describe '#find_user' do
    context 'raw info hash attributes empty' do
      let(:raw_info_attr) { {} }

      it 'does not mark user as external' do
        stub_saml_group_config(%w[Freelancers])

        expect(saml_user.find_user.external).to be_falsy
      end
    end

    context 'when the external_providers config includes saml' do
      before do
        stub_omniauth_saml_config(external_providers: [provider], block_auto_created_users: false)
        stub_saml_group_config(%w[Freelancers])
      end

      it 'marks external:true for all users, regardless of the existence of external_groups', :aggregate_failures do
        saml_user.find_user

        saml_user.save # rubocop:disable Rails/SaveBang -- Gitlab::Auth::OAuth::User#save is a custom method
        expect(gl_user).to be_valid
        expect(gl_user).to be_truthy
        expect(gl_user.external).to be_truthy
      end
    end
  end

  describe '#bypass_two_factor?' do
    let(:saml_config) { mock_saml_config_with_upstream_two_factor_authn_contexts }

    subject { saml_user.bypass_two_factor? }

    context 'with authn_contexts_worth_two_factors configured' do
      before do
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [saml_config])
      end

      it 'returns true when authn_context is worth two factors' do
        allow(saml_user.auth_hash).to receive(:authn_context).and_return('urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS')
        is_expected.to be_truthy
      end

      it 'returns false when authn_context is not worth two factors' do
        allow(saml_user.auth_hash).to receive(:authn_context).and_return('urn:oasis:names:tc:SAML:2.0:ac:classes:Password')
        is_expected.to be_falsey
      end

      it 'returns false when authn_context is blank' do
        is_expected.to be_falsey
      end
    end

    context 'without auth_contexts_worth_two_factors_configured' do
      before do
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [mock_saml_config])
      end

      it 'returns false when authn_context is present' do
        allow(saml_user.auth_hash).to receive(:authn_context).and_return('urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS')
        is_expected.to be_falsey
      end

      it 'returns false when authn_context is blank' do
        is_expected.to be_falsey
      end
    end
  end
end
