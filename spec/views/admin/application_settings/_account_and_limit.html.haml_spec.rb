# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_account_and_limit.html.haml', feature_category: :settings do
  let(:app_settings) { build(:application_setting) }
  let(:user) { build_stubbed(:admin) }

  before do
    assign(:application_setting, app_settings)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'session expire from init' do
    context 'when session_expire_from_init is enabled' do
      it 'has the setting section' do
        render

        expect(rendered).to have_content('Session settings')
        expect(rendered).to have_field('Expire from time of session creation',
          type: 'radio')
      end
    end
  end

  describe ':oauth_access_token_expires_in' do
    it 'renders the oauth_access_token_expires_in attributes and text' do
      render

      expect(rendered).to have_field(
        'application_setting[oauth_access_token_expires_in]', type: 'number', placeholder: '7200'
      )
      expect(rendered).to have_selector('input[name="application_setting[oauth_access_token_expires_in]"][min="300"]')
      expect(rendered).to have_selector(
        'input[name="application_setting[oauth_access_token_expires_in]"][max="7200"]'
      )
      expect(rendered).to have_text('Maximum allowable lifetime for OAuth access tokens')
      expect(rendered).to have_text(
        'Maximum lifetime of OAuth access tokens in seconds. Minimum 300 (5 minutes). ' \
          'If blank, defaults to 7200 (2 hours). Does not change the lifetime of any existing tokens.'
      )
    end
  end
end
