# frozen_string_literal: true

RSpec.shared_examples 'hardware device for 2fa' do |device_type|
  include Features::TwoFactorHelpers
  include Spec::Support::Helpers::ModalHelpers

  def register_device(device_type, **kwargs)
    case device_type
    when 'WebAuthn'
      webauthn_device_registration(**kwargs)
    else
      raise "Unknown device type #{device_type}"
    end
  end

  describe "registration" do
    let(:user) { create(:user) }

    before do
      gitlab_sign_in(user)
      user.update_attribute(:otp_required_for_login, true)
    end

    describe 'when 2FA via OTP is disabled' do
      before do
        user.update_attribute(:otp_required_for_login, false)
      end

      it 'allows registering a new device' do
        visit profile_account_path
        click_on _('Enable two-factor authentication')

        device = register_device(device_type, password: user.password)
        expect(page).to have_content("Your #{device_type} device was registered")
        copy_recovery_codes
        manage_two_factor_authentication

        expect(page).to have_content(device.name)
      end
    end

    describe 'when 2FA via OTP is enabled' do
      it 'allows registering a new device with a name' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content(_("You've already enabled two-factor authentication using a one-time password authenticator. In order to register a different device, you must first delete this authenticator."))

        device = register_device(device_type, password: user.password)
        expect(page).to have_content("Your #{device_type} device was registered")
        copy_recovery_codes
        manage_two_factor_authentication

        expect(page).to have_content(device.name)
      end

      it 'allows deleting a device' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content(_("You've already enabled two-factor authentication using a one-time password authenticator. In order to register a different device, you must first delete this authenticator."))

        first_device = register_device(device_type, password: user.password)
        copy_recovery_codes
        manage_two_factor_authentication
        second_device = register_device(device_type, name: 'My other device', password: user.password)

        expect(page).to have_content(first_device.name)
        expect(page).to have_content(second_device.name)

        click_button _('Delete WebAuthn device'), match: :first if device_type == 'WebAuthn'

        within_modal do
          fill_in _('Current password'), with: user.password
          find_by_testid('2fa-action-primary').click
        end

        expect(page).to have_content('Successfully deleted')
        expect(page.body).not_to have_content(first_device.name)
        expect(page.body).to have_content(second_device.name)
      end
    end
  end

  describe 'fallback code authentication', :js do
    let(:user) { create(:user) }

    before do
      # Register and logout
      gitlab_sign_in(user)
      user.update_attribute(:otp_required_for_login, true)
      visit profile_account_path
    end

    describe 'when no device is registered' do
      before do
        gitlab_sign_out
        gitlab_sign_in(user)
      end

      it 'shows the fallback otp code UI' do
        assert_fallback_ui(page)
      end
    end

    describe 'when a device is registered' do
      before do
        manage_two_factor_authentication
        register_device(device_type, password: user.password)
        gitlab_sign_out
        gitlab_sign_in(user)
      end

      it 'provides a button that shows the fallback otp code UI' do
        click_button(_('Sign in via 2FA code'))

        assert_fallback_ui(page)
      end
    end
  end
end
