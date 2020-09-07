# frozen_string_literal: true

RSpec.shared_examples 'hardware device for 2fa' do |device_type|
  include Spec::Support::Helpers::Features::TwoFactorHelpers

  def register_device(device_type, **kwargs)
    case device_type.downcase
    when "u2f"
      register_u2f_device(**kwargs)
    when "webauthn"
      register_webauthn_device(**kwargs)
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

      it 'does not allow registering a new device' do
        visit profile_account_path
        click_on 'Enable two-factor authentication'

        expect(page).to have_button("Set up new device", disabled: true)
      end
    end

    describe 'when 2FA via OTP is enabled' do
      it 'allows registering a new device with a name' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content("You've already enabled two-factor authentication using one time password authenticators")

        device = register_device(device_type)

        expect(page).to have_content(device.name)
        expect(page).to have_content("Your #{device_type} device was registered")
      end

      it 'allows deleting a device' do
        visit profile_account_path
        manage_two_factor_authentication
        expect(page).to have_content("You've already enabled two-factor authentication using one time password authenticators")

        first_device = register_device(device_type)
        second_device = register_device(device_type, name: 'My other device')

        expect(page).to have_content(first_device.name)
        expect(page).to have_content(second_device.name)

        accept_confirm { click_on 'Delete', match: :first }

        expect(page).to have_content('Successfully deleted')
        expect(page.body).not_to have_content(first_device.name)
        expect(page.body).to have_content(second_device.name)
      end
    end
  end

  describe 'fallback code authentication' do
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
        register_device(device_type)
        gitlab_sign_out
        gitlab_sign_in(user)
      end

      it 'provides a button that shows the fallback otp code UI' do
        expect(page).to have_link('Sign in via 2FA code')

        click_link('Sign in via 2FA code')

        assert_fallback_ui(page)
      end
    end
  end
end
