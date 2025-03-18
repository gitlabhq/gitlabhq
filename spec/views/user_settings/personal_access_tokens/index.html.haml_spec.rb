# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/personal_access_tokens/index.html.haml', feature_category: :system_access do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need these objects to be persisted
  let(:user) { create(:user) }
  let(:personal_access_token) { create(:personal_access_token, user: user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    assign(:user, user)
    sign_in(user)
    allow(view).to receive(:current_user).and_return(user)

    assign(:active_access_tokens, ::PersonalAccessTokenSerializer.new.represent([personal_access_token]))
    assign(:personal_access_token, personal_access_token)
    assign(:scopes, [:api, :read_api])
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(dpop_authentication: false)
    end

    it 'does not show dpop options' do
      render

      expect(rendered).not_to have_selector('[data-testid="dpop-form"]')
    end
  end

  context 'when feature flag is enabled' do
    before do
      stub_feature_flags(dpop_authentication: true)
    end

    it 'shows dpop options' do
      render

      expect(rendered).to have_selector('[data-testid="dpop-form"]')
    end

    it 'shows ticked checkbox for DPoP when it is enabled' do
      user.update!(dpop_enabled: true)
      render

      expect(rendered).to have_checked_field('user[dpop_enabled]', class: 'custom-control-input')
    end

    it 'shows unticked checkbox for DPoP when it is disabled' do
      user.update!(dpop_enabled: false)
      render

      expect(rendered).not_to have_checked_field('user[dpop_enabled]', class: 'custom-control-input')
    end
  end
end
