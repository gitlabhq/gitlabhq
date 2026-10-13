# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/preferences/show', feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create_default(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'appearance' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#appearance')
    end

    it 'passes the color modes to the color mode selector and the footer app' do
      color_modes = Gitlab::ColorModes.available_modes.to_json

      expect(rendered).to have_css('#js-color-mode-selector') { |el| el['data-color-modes'] == color_modes }
      expect(rendered).to have_css('#js-profile-preferences-app') { |el| el['data-color-modes'] == color_modes }
    end
  end

  describe 'syntax highlighting theme' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#syntax-highlighting-theme')
    end
  end

  describe 'behavior' do
    before do
      render
    end

    it 'has option for Render whitespace characters in the Web IDE' do
      expect(rendered).to have_unchecked_field('Render whitespace characters in the Web IDE')
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#behavior')
    end

    it 'has helpful homepage setup guidance' do
      expect(rendered).to have_selector('[data-label="Homepage"]')
      expect(rendered).to have_selector("[data-description=" \
                                        "'Choose what content you want to see by default on your homepage.']")
    end
  end

  describe 'localization' do
    before do
      render
    end

    it 'has an id for anchoring' do
      expect(rendered).to have_css('#localization')
    end
  end

  describe 'integrations' do
    context 'when there are integrations to show' do
      before do
        allow(view).to receive(:integration_views).and_return([{ name: 'sourcegraph' }])

        render
      end

      it 'renders the section with the mount point inside the form' do
        expect(rendered).to have_css('form#profile-preferences-form #integrations.settings-section',
          text: s_('Preferences|Integrations'))

        mount_point = Capybara.string(rendered).find('#integrations #js-profile-preferences-integrations')
        expect(Gitlab::Json::SafeParser.parse(mount_point['data-integration-views']))
          .to eq([{ 'name' => 'sourcegraph' }])
        expect(Gitlab::Json::SafeParser.parse(mount_point['data-user-fields']).keys)
          .to match_array(%w[gitpod_enabled sourcegraph_enabled extensions_marketplace_enabled])
        expect(mount_point['data-extensions-marketplace-url']).to be_present
      end
    end

    context 'when there are no integrations' do
      before do
        allow(view).to receive(:integration_views).and_return([])

        render
      end

      it 'does not render the section' do
        expect(rendered).to have_no_css('#integrations')
        expect(rendered).to have_css('form#profile-preferences-form #js-profile-preferences-app')
      end
    end
  end
end
