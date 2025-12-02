# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PasskeysController, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user, :with_namespace) }

  before do
    sign_in(user)

    allow(described_class).to receive(:current_user).and_return(user)
  end

  shared_examples 'user must enter a valid current password' do
    let(:error_message) { { message: _('You must provide a valid current password.') } }

    it 'shows an error message' do
      bad

      error = assigns[:error] || assigns[:webauthn_error]

      expect(error).to eq(error_message)
    end

    it "validates password attempts" do
      expect { bad }.to change { user.failed_attempts }.from(0).to(1)
      expect { go }.not_to change { user.failed_attempts }
    end

    it_behaves_like 'prepares the .setup_passkey_registration_page'

    context 'when user authenticates with an external service' do
      before do
        allow(user).to receive(:password_automatically_set?).and_return(true)
      end

      it 'does not require the current password' do
        bad

        expect(assigns[:error]).not_to eq(error_message)
      end
    end

    context 'when password authentication is disabled' do
      before do
        stub_application_setting(password_authentication_enabled_for_web: false)
      end

      it 'does not require the current password' do
        bad

        expect(assigns[:error]).not_to eq(error_message)
      end
    end

    context 'when the user is an LDAP user' do
      before do
        allow(user).to receive(:ldap_user?).and_return(true)
      end

      it 'does not require the current password' do
        bad

        expect(assigns[:error]).not_to eq(error_message)
      end
    end
  end

  shared_examples 'successfully loads the page' do
    it 'returns a 200 status code' do
      go

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'page is not found' do
    it 'returns a 404 status' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'prepares the .setup_passkey_registration_page' do
    it 'renders relevant view variables', :freeze_time do
      stored_passkey = create(:webauthn_registration, :passkey, user: user)

      bad

      user.reload

      rendered_passkey = assigns[:passkeys].last

      expect(assigns[:passkeys].count).to eq(user.passkeys.count)
      expect(rendered_passkey[:name]).to eq(stored_passkey.name)
      expect(rendered_passkey[:created_at]).to eq(stored_passkey.created_at)
      expect(rendered_passkey[:last_used_at]).to eq(stored_passkey.last_used_at)
      expect(rendered_passkey[:delete_path]).to eq(profile_passkey_path(stored_passkey))
    end

    context 'with a webauthn user handle (webauthn_xid for the user.id key during webauthn creation)' do
      context 'when the user does not have a webauthn_xid' do
        before do
          user.user_detail.update!(webauthn_xid: nil)
        end

        it 'generates a new webauthn_xid' do
          expect(user.webauthn_xid).to be_nil

          bad

          expect(user.webauthn_xid).to be_present
        end
      end

      context 'when the user already has a webauthn_xid' do
        before do
          user.user_detail.update!(webauthn_xid: WebAuthn.generate_user_id)
        end

        it 'does not generate a new webauthn_xid' do
          expect(user.webauthn_xid).to be_present

          bad

          expect(user.webauthn_xid).to be_present
        end
      end
    end
  end

  shared_examples 'tracks a passkey interval event' do
    it 'calls the interval event' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:track_passkey_internal_event)
      end

      go
    end
  end

  context 'when passkeys flag is off' do
    before do
      stub_feature_flags(passkeys: false)
    end

    describe 'GET new' do
      before do
        get new_profile_passkey_path
      end

      it_behaves_like 'page is not found'
    end

    describe 'POST create' do
      before do
        post profile_passkeys_path
      end

      it_behaves_like 'page is not found'
    end

    describe 'DELETE destroy' do
      before do
        delete profile_passkey_path(1)
      end

      it_behaves_like 'page is not found'
    end
  end

  context 'when passkeys flag is on' do
    describe 'GET new' do
      def go
        get new_profile_passkey_path
      end

      it_behaves_like 'prepares the .setup_passkey_registration_page' do
        def bad
          go
        end
      end

      it_behaves_like 'successfully loads the page'
      it_behaves_like 'tracks a passkey interval event'
    end

    describe 'POST create' do
      let(:client) { WebAuthn::FakeClient.new('http://localhost', encoding: :base64) } # Matches config.encoding
      let(:credential) { create_credential(client: client, rp_id: request.host) }

      let(:params) do
        { device_registration: { name: '1Password', device_response: device_response }, current_password: 'fake' }
      end

      let(:params_with_password) do
        { device_registration: { name: 'LastPass', device_response: device_response }, current_password: user.password }
      end

      before do
        allow_next_instance_of(Profiles::PasskeysController) do |instance|
          allow(instance).to receive(:session).and_return({
            challenge: challenge
          })
        end
      end

      def bad
        post profile_passkeys_path, params: params
      end

      def go
        post profile_passkeys_path, params: params_with_password
      end

      def challenge
        @_challenge ||= begin
          options_for_create = WebAuthn::Credential.options_for_create(
            user: {
              id: user.webauthn_xid,
              name: user.username,
              display_name: user.name
            },
            exclude: user.get_all_webauthn_credential_ids,
            authenticator_selection: {
              user_verification: 'required',
              resident_key: 'required'
            },
            rp: { name: 'GitLab' },
            extensions: { credProps: true }
          )
          options_for_create.challenge
        end
      end

      def device_response
        client.create(challenge: challenge).to_json # rubocop:disable Rails/SaveBang -- .create is a FakeClient method
      end

      it_behaves_like 'user must enter a valid current password'

      context "when valid password is given" do
        context "when registration succeeds" do
          it "registers and redirects back to the 2FA profile page" do
            count = user.passkeys.count

            go

            expect(user.passkeys.count).to be(count + 1)
            expect(response).to redirect_to(profile_two_factor_auth_path)
            expect(flash[:notice]).to match(
              /Passkey added successfully! Next time you sign in, select the sign-in with passkey option./
            )
          end

          context 'with an interval event' do
            before do
              allow_next_instance_of(Authn::Passkey::RegisterService) do |instance|
                allow(instance).to receive(:execute).and_return(
                  ServiceResponse.success(message: _('Passkey successfully registered.'), payload: user)
                )
              end
            end

            it_behaves_like 'tracks a passkey interval event'
          end
        end

        context 'when registration fails' do
          context "with a service error" do
            def challenge
              Base64.strict_encode64(SecureRandom.random_bytes(16)) # Throws a challenge error
            end

            it "redirects back to the 2FA profile page with an alert" do
              go

              expect { response }.not_to change { user.passkeys.count }
              expect(response).to redirect_to(profile_two_factor_auth_path)
              expect(flash[:alert]).to be_present
            end
          end

          context 'with an interval event' do
            before do
              allow_next_instance_of(Authn::Passkey::RegisterService) do |instance|
                allow(instance).to receive(:execute).and_return(
                  ServiceResponse.error(message: _('Passkey registration failed.'))
                )
              end
            end

            it_behaves_like 'tracks a passkey interval event'
          end
        end
      end
    end

    describe 'DELETE destroy' do
      let_it_be_with_reload(:user) do
        create(:user, :with_passkey, :with_namespace)
      end

      let(:passkey) { user.passkeys.first }
      let(:current_password) { user.password }

      def go
        delete profile_passkey_path(passkey), params: { current_password: current_password }
      end

      def bad
        delete profile_passkey_path(passkey), params: { current_password: 'wrong' }
      end

      it_behaves_like 'user must enter a valid current password'

      context "when a valid password is given" do
        context 'when authentication succeeds' do
          it 'destroys the passkey' do
            expect { go }.to change { user.passkeys.count }.by(-1)
          end

          it 'invalidates all but the current_user ActiveSession' do
            expect_next_instance_of(described_class) do |instance|
              expect(instance).to receive(:destroy_all_but_current_user_session!)
            end

            go
          end

          it "redirects back to the 2FA profile page with a backend service notice" do
            go

            expect(response).to redirect_to(profile_two_factor_auth_path)
            expect(flash[:notice]).to match(
              /Passkey has been deleted!/
            )
          end
        end

        context 'when deletion fails' do
          context 'with an unauthorized user' do
            before do
              allow(Ability).to receive(:allowed?).and_call_original
              allow(Ability).to receive(:allowed?)
                .with(user, :disable_passkey, user)
                .and_return(false)
            end

            it "redirects back to the 2FA profile page with a backend service alert" do
              go

              expect(response).to redirect_to(profile_two_factor_auth_path)
              expect(flash[:alert]).to match(/You are not authorized to perform this action/)
            end

            it 'does not destroy the passkey' do
              count = user.passkeys.count

              go

              expect(user.passkeys.count).to eq(count)
            end
          end
        end
      end
    end
  end
end
