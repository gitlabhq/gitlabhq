# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/personal_access_tokens/index.html.haml', feature_category: :system_access do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need these objects to be persisted
  let(:user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    sign_in(user)

    assign(:access_token_params, { name: 'new token', description: nil, scopes: [] })
  end

  it 'shows the personal access tokens' do
    render

    expect(rendered).to have_selector('div#js-shared-access-token-app[data-access-token-name="new token"]')
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
