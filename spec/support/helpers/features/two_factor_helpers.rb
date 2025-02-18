# frozen_string_literal: true

# These helpers allow you to manage and register
# U2F and WebAuthn devices
#
# Usage:
#   describe "..." do
#   include Features::TwoFactorHelpers
#     ...
#
#   manage_two_factor_authentication
#
module Features
  module TwoFactorHelpers
    def copy_recovery_codes
      click_on _('Copy codes')
      click_on _('Proceed')
    end

    def enable_two_factor_authentication
      click_on _('Enable two-factor authentication')
      expect(page).to have_content(_('Set up new device'))
      wait_for_requests
    end

    def manage_two_factor_authentication
      click_on 'Manage two-factor authentication'
      expect(page).to have_content("Set up new device")
      wait_for_requests
    end

    # Registers webauthn device via UI
    def webauthn_device_registration(webauthn_device: nil, name: 'My device', password: 'fake')
      webauthn_device ||= FakeWebauthnDevice.new(page, name)
      webauthn_device.respond_to_webauthn_registration
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

      options_for_create = WebAuthn::Credential.options_for_create(
        user: { id: user.webauthn_xid, name: user.username },
        authenticator_selection: { user_verification: 'discouraged' },
        rp: { name: 'GitLab' }
      )
      challenge = options_for_create.challenge

      device_response = fake_device.create(challenge: challenge).to_json # rubocop:disable Rails/SaveBang
      device_registration_params = { device_response: device_response,
                                     name: name }

      Webauthn::RegisterService.new(
        user, device_registration_params, challenge).execute
      FakeWebauthnDevice.new(page, name, fake_device)
    end

    def assert_fallback_ui(page)
      expect(page).to have_button('Verify code')
      expect(page).to have_css('#user_otp_attempt')
      expect(page).not_to have_link('Sign in via 2FA code')
      expect(page).not_to have_css("#js-authenticate-token-2fa")
    end
  end
end
