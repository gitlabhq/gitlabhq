# frozen_string_literal: true

# These helpers allow you to manage and register
# WebAuthn devices
#
# Usage:
#   describe "..." do
#   include Features::TwoFactorHelpers
#     ...

module Features
  module TwoFactorHelpers
    include Spec::Support::Helpers::ModalHelpers

    ## OTP
    #
    def copy_recovery_codes
      click_on _('Copy codes')
      click_on _('Proceed')
    end

    # Register OTP authenticator via UI
    def otp_authenticator_registration(pin, password = nil)
      click_button _('Register authenticator')
      fill_in 'current_password', with: password if password
      fill_in 'pin_code', with: pin
      click_button _('Register with two-factor app')
    end

    def otp_authenticator_registration_and_copy_codes(pin, password = nil)
      otp_authenticator_registration(pin, password)
      click_button _('Copy codes')
      click_link _('Proceed')
    end

    # Add OTP for authentication via UI
    def add_otp(user)
      click_button _("Sign in via 2FA code")
      otp_code = user.current_otp
      fill_in _('Enter verification code'), with: otp_code
      click_button _('Verify code')
    end

    ## WebAuthn (second_factor_authenticators)
    #
    # Registers webauthn device via UI
    def webauthn_device_registration(webauthn_device: nil, name: 'My device', password: 'fake')
      webauthn_device ||= FakeWebauthnDevice.new(page, name)
      webauthn_device.respond_to_webauthn_registration
      click_on _('Register device')
      wait_for_requests
      click_on _('Set up new device')
      webauthn_fill_form_and_submit(name: name, password: password)
      webauthn_device
    end

    def webauthn_fill_form_and_submit(name: 'My device', password: 'fake')
      content = _('Your device was successfully set up! Give it a name and register it with the GitLab server.')
      expect(page).to have_content(content)

      within '[data-testid="create-webauthn"]' do
        fill_in _('Device name'), with: name
        fill_in _('Current password'), with: password
        click_on _('Register device')
      end
    end

    # Adds webauthn device directly via database
    def add_webauthn_device(app_id, user, fake_device = nil, name: 'My device')
      fake_device ||= WebAuthn::FakeClient.new(app_id)

      options_for_create = webauthn_options(user)
      challenge = options_for_create.challenge

      device_response = fake_device.create(challenge: challenge).to_json # rubocop:disable Rails/SaveBang
      device_registration_params = { device_response: device_response,
                                     name: name }

      Webauthn::RegisterService.new(
        user, device_registration_params, challenge).execute
      FakeWebauthnDevice.new(page, name, fake_device)
    end

    def delete_webauthn_device(password: 'fake')
      click_button _('Delete WebAuthn device')

      expect(page).to have_content('Are you sure you want to delete this')

      within_modal do
        fill_in _('Current password'), with: password
        click_button _('Delete WebAuthn device')
      end
    end

    def webauthn_options(user)
      WebAuthn::Credential.options_for_create(
        user: {
          id: user.webauthn_xid,
          name: user.username,
          display_name: user.name
        },
        exclude: user.get_all_webauthn_credential_ids,
        authenticator_selection: {
          user_verification: 'discouraged',
          resident_key: 'preferred'
        },
        rp: { name: 'GitLab' },
        extensions: { credProps: true }
      )
    end

    def assert_fallback_ui(page)
      expect(page).to have_button('Verify code')
      expect(page).to have_css('#user_otp_attempt')
      expect(page).not_to have_link('Sign in via 2FA code')
      expect(page).not_to have_css("#js-authenticate-token-2fa")
    end

    ## Passkeys
    #
    # Registers a passkey via the UI
    #
    # (Optional) Accepts a block to mock bad authenticator responses (`:device_response`)
    #
    def passkey_registration(name: 'My Passkey', password: 'fake')
      click_on _('Add passkey')

      wait_for_requests

      # Redirect to passkeys#new
      expect(page).to have_content(_('Add passkey'))

      # Since the onRegister() Vue function is called immediately in passkeys#new page,
      # we need to re-send the request options to have authenticator's response (`device_response`)
      # in the Rails params hash that can then to used in the onRegister(), by
      # re-trying the POST request
      #
      # It tries to simulate:
      #
      # - On clicking "Add passkey", immediately mock `navigator.credentials.create`
      # - In passkey#new, handle the success() state & show name/password form
      #
      passkey ||= FakeWebauthnDevice.new(page, name)
      block_given? ? yield : passkey.respond_to_webauthn_registration

      click_button _('Try again') # Start of user interaction

      wait_for_requests

      passkey_fill_form_and_submit(name: name, password: password)

      passkey
    end

    # Redirects back to two_factor_auths#show on success
    #
    # Stays on passkeys#new on failure
    def passkey_fill_form_and_submit(name: 'My Passkey', password: 'fake')
      within '[data-testid="passkey-registration-success"]' do
        fill_in _('Current password'), with: password
        fill_in _('Passkey name'), with: name
        click_on _('Add passkey')
      end
    end

    # Adds a passkey to the database & sends the browser response for authentication
    def add_passkey(app_id, user, fake_device = nil, name: 'My passkey', save_passkey: true)
      fake_device ||= WebAuthn::FakeClient.new(app_id)

      options_for_create = passkey_webauthn_options(user)
      challenge = options_for_create.challenge
      options = {
        challenge: challenge,
        user_verified: true,
        extensions: { "credProps" => { "rk" => true } }
      }
      device_response = fake_device.create(**options).to_json # rubocop:disable Rails/SaveBang
      device_registration_params = { device_response: device_response, name: name }

      Authn::Passkey::RegisterService.new(user, device_registration_params, challenge).execute if save_passkey

      FakeWebauthnDevice.new(page, name, fake_device) # Simulates the browser
    end

    def delete_passkey_device(password: 'fake')
      click_button _('Disable passkey sign-in')

      expect(page).to have_content('Are you sure you want to delete this')

      within_modal do
        fill_in _('Current password'), with: password
        click_button _('Disable passkey sign-in')
      end
    end

    def passkey_webauthn_options(user)
      WebAuthn::Credential.options_for_create(
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
    end
  end
end
