# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/users/show.html.haml', feature_category: :system_access do
  let_it_be(:user) { build_stubbed(:user, :with_namespace) }

  let(:current_user) { build_stubbed(:admin) }
  let(:page) { Nokogiri::HTML.parse(rendered) }
  let(:two_factor_status) { page.at('.two-factor-status') }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(current_user)
  end

  describe 'user 2FA status' do
    it 'shows the label' do
      render

      expect(two_factor_status).to have_text 'Two-factor Authentication:'
    end

    context 'when user has 2FA disabled' do
      before do
        allow(user).to receive(:two_factor_enabled?).and_return(false)
        render
      end

      it 'shows Disabled text' do
        expect(two_factor_status).to have_text 'Disabled'
      end

      it 'does not show Disable link button' do
        expect(two_factor_status).not_to have_link 'Disable'
      end
    end

    context 'when user has 2FA enabled' do
      let(:admin?) { true }

      before do
        allow(user).to receive(:two_factor_enabled?).and_return(true)
        allow(current_user).to receive(:admin?).and_return(admin?)
        render
      end

      it 'shows Enabled text' do
        expect(two_factor_status).to have_text 'Enabled'
      end

      it 'shows Disable link button' do
        expect(two_factor_status).to have_link 'Disable'
      end

      context 'when current user is not an admin' do
        let(:admin?) { false }

        it 'does not show Disable link button' do
          expect(two_factor_status).not_to have_link 'Disable'
        end
      end
    end
  end

  describe 'user email OTP status' do
    let(:email_otp_status) { page.at(%([data-testid="email-otp"])) }

    it 'shows the label' do
      render

      expect(email_otp_status).to have_text 'Email OTP:'
    end

    context 'when user has email OTP disabled' do
      it 'shows No text' do
        allow(user).to receive(:email_otp_required_after).and_return(nil)

        render

        expect(email_otp_status).to have_text 'No'
      end
    end

    context 'when user has email OTP enabled' do
      it 'shows Yes text' do
        now = Time.current
        allow(user).to receive(:email_otp_required_after).and_return(now)

        render

        expect(email_otp_status).to have_text "Yes (#{now.to_fs(:medium)})"
      end
    end
  end
end
