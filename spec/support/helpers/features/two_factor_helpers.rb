# frozen_string_literal: true
# These helpers allow you to manage and register
# U2F and WebAuthn devices
#
# Usage:
#   describe "..." do
#   include Spec::Support::Helpers::Features::TwoFactorHelpers
#     ...
#
#   manage_two_factor_authentication
#
module Spec
  module Support
    module Helpers
      module Features
        module TwoFactorHelpers
          def manage_two_factor_authentication
            click_on 'Manage two-factor authentication'
            expect(page).to have_content("Set up new device")
            wait_for_requests
          end

          def register_u2f_device(u2f_device = nil, name: 'My device')
            u2f_device ||= FakeU2fDevice.new(page, name)
            u2f_device.respond_to_u2f_registration
            click_on 'Set up new device'
            expect(page).to have_content('Your device was successfully set up')
            fill_in "Pick a name", with: name
            click_on 'Register device'
            u2f_device
          end

          # Registers webauthn device via UI
          def register_webauthn_device(webauthn_device = nil, name: 'My device')
            webauthn_device ||= FakeWebauthnDevice.new(page, name)
            webauthn_device.respond_to_webauthn_registration
            click_on 'Set up new device'
            expect(page).to have_content('Your device was successfully set up')
            fill_in 'Pick a name', with: name
            click_on 'Register device'
            webauthn_device
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
    end
  end
end
